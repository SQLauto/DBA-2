using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class WebDeployOperator : IDeploymentOperator<WebDeploy>
    {
        private readonly IDeploymentLogger _logger;
        private readonly IParameterService _parameterService;

        public WebDeployOperator(IParameterService parameterService = null, IDeploymentLogger logger = null)
        {
            _parameterService = parameterService ?? new ParameterService(logger);
            _logger = logger;
        }

        public bool PreDeploymentValidate(WebDeploy role, ConfigurationParameters parameters, List<string> outputLocations)
        {
            bool isPackageValid = true;
            bool isAppPoolValid = true;
            bool isTestValid = true;
            string packageName = "";
            string outputLocation = "";
            string packageLocation = "";
            var foundWebPackage = false;

            if (!string.IsNullOrEmpty(role.Package?.Name))
            {
                foreach (string location in outputLocations)
                {
                    packageName = $"{role.Package.Name}_Package";
                    outputLocation = location;
                    packageLocation = Path.Combine(outputLocation, "_PublishedWebsites", packageName);
                    if (Directory.Exists(packageLocation))
                    {
                        foundWebPackage = true;
                        break;
                    }
                }

                if (!foundWebPackage)
                {
                    isPackageValid = false;
                    _logger?.WriteWarn($"Package '{packageName}' cannot be found");
                }

                if (isPackageValid)
                {
                    // Server roles can override the root config and they can also over ride the base transform
                    // Lets determine what is happening for this server role
                    string configurationParameters = Path.Combine(outputLocation, "ConfigurationParameters");
                    bool overridenTransform = true;
                    bool overridenConfig = !parameters.RootConfig.Equals(parameters.OverriddenConfigName, StringComparison.CurrentCultureIgnoreCase);
                    string overriddenTransformName = overridenConfig ? parameters.OverriddenConfigName : parameters.EnvironmentName;

                    // Look for a config transform matching the overridden config
                    var setParametersFile = Path.Combine(configurationParameters,
                        $"{role.Package.Name}.{overriddenTransformName}.xml");

                    // If it doesnt exist, use the default transform
                    if (!File.Exists(setParametersFile))
                    {
                        overridenTransform = false;
                        setParametersFile = Path.Combine(configurationParameters, $"{role.Package.Name}.Transform.xml");
                    }

                    if (!File.Exists(setParametersFile))
                    {
                        isPackageValid = false;
                        _logger?.WriteWarn(
                            $"Set parameters file '{setParametersFile}' cannot be found in '{configurationParameters}'. (Use overridden set parameters transform = {overridenTransform})");
                    }

                    // Verify every tokenised parameter is defined in the root parameters file
                    //var parameterService = new ParameterService();
                    var deployParams = parameters.TargetParameters.Dictionary;

                    var paramsToValidate = _parameterService.GetParametersFromConfig(setParametersFile); // use the unresolved value here

                    // 112236: This validate now needs to know whether to let lookups through so checking key list isn't enough
                    //if (!_parameterService.ValidateParameterList(paramsToValidate.Dictionary.Keys.ToList(), deployParams))
                    if (!_parameterService.ValidateParameterList(paramsToValidate, deployParams))
                    {
                        _logger?.WriteWarn($"Validation failed for file '{setParametersFile}'");
                        isPackageValid = false;
                    }
                }
            }

            //APP POOL CHECKS
            if (role.AppPool != null)
            {
                if (role.AppPool.ServiceAccount != "NetworkService" && role.AppPool.ServiceAccount != "ApplicationPoolIdentity")
                {
                    if (!string.IsNullOrEmpty(role.AppPool.ServiceAccount))
                    {
                        isAppPoolValid = parameters.ServiceAccounts.Any(s => s.LookupName.Equals(role.AppPool.ServiceAccount,
                            StringComparison.InvariantCultureIgnoreCase));

                        if (!isAppPoolValid)
                        {
                            _logger?.WriteWarn(
                                $"Service account '{role.AppPool.ServiceAccount}' cannot be found in the relevant service accounts file");
                        }
                    }
                }

                if (role.AppPool.RecycleLogEvents != null)
                {
                    foreach (var flag in role.AppPool.RecycleLogEvents.Where(f => !IsValidRecycleEventFlag(f)))
                    {
                        isAppPoolValid = false;
                        _logger?.WriteWarn(
                            $"{flag} is not a valid attribute for the Application Pool Event Log on Recycle setting");
                    }
                }
            }

            foreach (var endPointTest in role.TestInfo?.EndPoints ?? Enumerable.Empty<WebTestEndPoint>())
            {
                if (string.IsNullOrEmpty(endPointTest.TestIdentity))
                    continue;

                var found = parameters.ServiceAccounts.Any(s => s.LookupName.Equals(endPointTest.TestIdentity,
                    StringComparison.InvariantCultureIgnoreCase));

                if (!found)
                {
                    _logger?.WriteWarn(
                        $"Service account '{endPointTest.TestIdentity}' cannot be found in the relevant service accounts file");
                }

                isTestValid &= found;
            }

            return isPackageValid && isAppPoolValid && isTestValid;
        }

        //public bool PostDeploymentValidate(PostDeployParameters postDeployParameters, WebDeploy role) => true;

        private readonly IList<string> _recycleEventFlags = new List<string> { "ConfigChange", "IsapiUnhealthy", "Memory", "OnDemand", "PrivateMemory", "Requests", "Schedule", "Time" };

        private bool IsValidRecycleEventFlag(string flag)
        {
            var trimmedFlag = flag.Trim();
            return _recycleEventFlags.Any(s => s.Equals(trimmedFlag, StringComparison.InvariantCultureIgnoreCase));
        }

        public IList<ArchiveEntry> GetDeploymentFiles(WebDeploy role, List<string> dropFolders, ConfigurationParameters parameters)
        {
            var files = new List<ArchiveEntry>();

            if (string.IsNullOrEmpty(role.Package.Name))
                return files;

            string packageName = $"{role.Package.Name}_Package";
            string packageLocation = string.Empty;
            string dropFolder = string.Empty;
            foreach (var dropFolderToLookIn in dropFolders)
            {
                packageLocation = Path.Combine(dropFolderToLookIn, "_PublishedWebsites", packageName);
                if (Directory.Exists(packageLocation))
                {
                    dropFolder = dropFolderToLookIn;
                    break;
                }
            }

            var packageFiles = new List<string>(Directory.GetFiles(packageLocation, "*.*", SearchOption.AllDirectories));

            // Handle the set parameters file
            var targetParametersFile = packageFiles.SingleOrDefault(x => x.Contains("SetParameters.xml"));

            // Remove the original set parameters file from the list and package the other files first
            packageFiles.Remove(targetParametersFile);

            files.AddRange(packageFiles.Select(file => new ArchiveEntry
            {
                FileLocation = file,
                FileRelativePath = FileHelper.GetFileRelativePath(file, dropFolder),
                FileName = string.Empty
            }));

            // Add the target environment specific set parameters file
            // Server roles can override the root config and they can also over ride the base transform
            // Lets determine what is happening for this server role
            bool overridenConfig = !parameters.RootConfig.Equals(parameters.OverriddenConfigName, StringComparison.CurrentCultureIgnoreCase);
            string overriddenTransformName = overridenConfig ? parameters.OverriddenConfigName : parameters.EnvironmentName;

            // Look for a config transform matching the overridden config
            string sourceParametersFile = Path.Combine(dropFolder, "ConfigurationParameters",
                $"{role.Package.Name}.{overriddenTransformName}.xml");
            var packagedName =
                $"{Path.GetFileNameWithoutExtension(targetParametersFile)}.{overriddenTransformName}.Transform.xml";

            if (!File.Exists(sourceParametersFile))
            {
                sourceParametersFile = Path.Combine(dropFolder, "ConfigurationParameters",
                    $"{role.Package.Name}.Transform.xml");
                packagedName = $"{Path.GetFileNameWithoutExtension(targetParametersFile)}.Transform.xml";
            }

            files.Add(new ArchiveEntry
            {
                FileLocation = sourceParametersFile,
                FileRelativePath = FileHelper.GetFileRelativePath(targetParametersFile, dropFolder),
                FileName = packagedName
            });

            return files;
        }

        public bool PostDeploymentValidate(PostDeployParameters parameters, WebDeploy role)
        {
            bool isValid = true;

            _logger?.WriteLine("Starting WebSite End Point Testing");

            using (var timer = new PerformanceLogger(_logger))
            {
                foreach (var endPointTest in role.TestInfo.EndPoints)
                {
                    string url = string.Empty;
                    var authenticationModes = role.Site.AuthenticationModes;
                    try
                    {
                        url = $"http://{parameters.Machine.ExternalIpAddress}";
                        url = role.Site.Port == default(ushort)
                            ? $"{url}/{endPointTest.Value}"
                            : $"{url}:{role.Site.Port}/{endPointTest.Value}";

                        var req = (HttpWebRequest)WebRequest.Create(url);
                        req.Method = "GET";
                        req.Timeout = (1000 * 240); // 4 minutes; default is 100 seconds

                        if (!string.IsNullOrEmpty(endPointTest.ContentType))
                        {
                            req.ContentType = endPointTest.ContentType;
                        }

                        var domain = string.Empty;
                        var username = string.Empty;
                        var password = string.Empty;

                        if (!string.IsNullOrEmpty(endPointTest.TestIdentity))
                        {
                            var account =
                                parameters.ServiceAccounts.Single(s => s.LookupName.Equals(endPointTest.TestIdentity, StringComparison.InvariantCultureIgnoreCase));
                            domain = account.Domain;
                            username = account.Username;
                            password = account.DecryptedPassword;
                        }


                        if (authenticationModes.Contains(WebAuthenticationMode.Windows) ||
                            authenticationModes.Contains(WebAuthenticationMode.Basic) ||
                            authenticationModes.Contains(WebAuthenticationMode.Digest) ||
                            endPointTest.Authentication != WebAuthenticationMode.Anonymous)
                        {
                            req.Credentials = new NetworkCredential(username, password, domain);
                            _logger?.WriteSummary($"Validating '{endPointTest.Value}' using '{domain}\\{username}' from service accounts file");
                        }
                        else
                        {
                            _logger?.WriteSummary($"Validating '{endPointTest.Value}'");
                        }

                        using (var response = req.GetResponse())
                        {
                            var newResponse = (HttpWebResponse)response;
                            var code = (int)newResponse.StatusCode;
                            _logger?.WriteSummary($"Code {code} returned ");

                            if (code >= 200 && code <= 307)
                            {
                                timer.WriteSummary($"{role.Description} Connection to '{url}' established. Time Elapsed:", LogResult.Success);
                            }
                            else
                            {
                                timer.WriteSummary($"{role.Description} Connection to '{url}' established but we recieved an error code. Time Elapsed:", LogResult.Fail);

                                isValid = false;
                            }
                        }

                    }
                    catch (Exception ex)
                    {
                        timer.WriteSummary(
                            $"{role.Description} Failed to connect to '{url}' Please check the detail log file for error message.", LogResult.Error);

                        _logger?.WriteError(ex);

                        if (authenticationModes.Contains(WebAuthenticationMode.Windows) ||
                            authenticationModes.Contains(WebAuthenticationMode.Basic) ||
                            authenticationModes.Contains(WebAuthenticationMode.Digest))
                        {
                            _logger?.WriteSummary("Was a password specified to decrypt the service account file?");
                        }
                        isValid = false;
                    }
                }

                timer.WriteSummary("Completed EndPoint Testing", isValid ? LogResult.Success : LogResult.Fail);
            }

            var isAppPoolValid = PostDeployValidateAppPools(role, parameters);

            return isValid && isAppPoolValid;
        }



        private bool PostDeployValidateAppPools(WebDeploy role, PostDeployParameters parameters)
        {
            if (role.AppPool == null)
                return true;

            var isValid = true;

            _logger?.WriteLine("Starting AppPool Testing");

            using (var timer = new PerformanceLogger(_logger))
            {
                string identityType;
                string serviceAccount = string.Empty;

                var appPoolAccount =
                    parameters.ServiceAccounts.FirstOrDefault(s => s.LookupName.Equals(role.AppPool.ServiceAccount, StringComparison.InvariantCultureIgnoreCase));

                var deploymentAccount =
                    parameters.ServiceAccounts.FirstOrDefault(s => s.LookupName == "DeploymentAccount");

                if (appPoolAccount != null)
                {
                    serviceAccount = appPoolAccount.QualifiedUsername;
                    identityType = "SpecificUser";
                }
                else if (deploymentAccount != null)
                {
                    identityType = role.AppPool.ServiceAccount == "NetworkService" ? "NetworkService" : "ApplicationPoolIdentity";
                }
                else
                {
                    identityType = role.AppPool.ServiceAccount == "NetworkService" ? "NetworkService" : "ApplicationPoolIdentity";
                }

                _logger?.WriteLine($"Identity type set to {identityType}");

                var psCommand = new StringBuilder();

                var deploymentServer = parameters.DeploymentMachine.ExternalIpAddress;
                var deploymentServerName = parameters.DeploymentMachine.Name;

                psCommand.Append(Environment.MachineName == deploymentServerName
                    ? $@"{parameters.DriveLetter}:\Deploy\DropFolder\Deployment\Scripts\AppPoolValidationTest.ps1 "
                    : $@"powershell -ExecutionPolicy Unrestricted -Command {
                            parameters.JumpFolder
                        }\Deployment\Scripts\AppPoolValidationTest.ps1 ");

                //psCommand.AppendFormat("-TargetMachine '{0}' ", parameters.Machine.Name);
                psCommand.AppendFormat("-TargetMachine '{0}' ", parameters.Machine.Name);
                psCommand.AppendFormat("-AppPoolName '{0}' ", role.AppPool.Name);
                psCommand.AppendFormat("-AppPoolIdentityType '{0}' ", identityType);

                if (identityType == "NetworkService")
                {
                    psCommand.Append("-AppPoolServiceAccount 'NetworkService' ");
                }
                else if (identityType == "ApplicationPoolIdentity")
                {
                    psCommand.Append("-AppPoolServiceAccount 'ApplicationPoolIdentity' ");
                }
                else
                {
                    psCommand.AppendFormat("-AppPoolServiceAccount '{0}' ", serviceAccount);
                }

                if (role.AppPool.IdleTimeout != default(int))
                {
                    psCommand.AppendFormat("-AppPoolTimeout '{0}' ", role.AppPool.IdleTimeout);
                }
                if (role.AppPool.RecycleLogEvents != null && role.AppPool.RecycleLogEvents.Any())
                {
                    string appPoolLogEventRecycleFlags = AppPoolLogEventRecycleFlagsCreate(role.AppPool.RecycleLogEvents);
                    psCommand.AppendFormat("-AppPoolEventLogRecycle '{0}' ", appPoolLogEventRecycleFlags);
                }
                string args = psCommand.ToString();

                _logger?.WriteLine($"Testing app pools using arguments {args}");

                var commandLineHelper = new CommandLineHelper(_logger);

                var username = deploymentAccount?.QualifiedUsername;
                var password = deploymentAccount?.DecryptedPassword;

                var exitCode = !string.IsNullOrWhiteSpace(deploymentServerName) && Environment.MachineName == deploymentServerName
                    ? commandLineHelper.PowershellCommand(args)
                    : commandLineHelper.RemotePowershellCommand(deploymentServer, args, username, password);

                isValid &= exitCode == 0;

                timer.WriteSummary($"Applying Application Pool ({role.AppPool.Name}) settings on server {parameters.Machine.Name}.",
                    isValid ? LogResult.Success : LogResult.Fail);

                timer.WriteSummary("Completed AppPool Testing", isValid ? LogResult.Success : LogResult.Fail);
            }

            return isValid;
        }

        private string AppPoolLogEventRecycleFlagsCreate(IList<string> recycleLogEvents)
        {
            int maxCount = recycleLogEvents.Count;
            int currentCount = 0;
            string recycleFlags = string.Empty;

            while (currentCount < maxCount)
            {
                if (currentCount != 0)
                {
                    recycleFlags += ",";
                }

                recycleFlags += recycleLogEvents[currentCount];
                currentCount++;
            }

            return recycleFlags;

        }
    }
}
 
 