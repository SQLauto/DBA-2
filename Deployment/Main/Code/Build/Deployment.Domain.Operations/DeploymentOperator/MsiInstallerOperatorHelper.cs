using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class MsiInstallerOperatorHelper
    {
        private readonly object _lock = new object();
        private readonly IDeploymentLogger _logger;
        private readonly IParameterService _parameterService;
        public MsiInstallerOperatorHelper(IParameterService parameterService = null, IDeploymentLogger logger = null)
        {
            _parameterService = parameterService;
            _logger = logger;
        }

        public bool DoConfigFilesExist(MsiDeploy role, string deploymentPath, bool fileExists, out IList<string> missingFiles)
        {
            var isValid = true;
            missingFiles = new List<string>();

            foreach (var configFile in role.Configs)
            {
                var filePath = Path.Combine(deploymentPath, configFile.Name);

                if (File.Exists(filePath) == fileExists)
                    continue;

                missingFiles.Add(configFile.Name);
                isValid = false;
            }

            return isValid;
        }

        public bool PreDeploymentValidate(MsiDeploy role, ConfigurationParameters parameters, List<string> outputLocations)
        {
            var isValid = true;
            var foundMsi = false;
            string msiDirectoryLocation = null;

            if (role.Action == MsiAction.Uninstall)
                return true;

            foreach (var location in outputLocations)
            {
                var msiLocation = Path.Combine(location, role.Msi.Name);
                if (!File.Exists(msiLocation)) continue;

                foundMsi = true;
                msiDirectoryLocation = Path.GetDirectoryName(msiLocation);
                _logger?.WriteLine($"MSI directory location set to {msiDirectoryLocation}");
                break;
            }

            if (!foundMsi || string.IsNullOrEmpty(msiDirectoryLocation))
            {
                _logger?.WriteWarn($"Msi file '{role.Msi.Name}' cannot be found");
                return false;
            }

            // Validate service accounts are specified in the accounts file
            foreach (var account in role.Accounts)
            {
                if (parameters.ServiceAccounts.Any(s => s.LookupName.Equals(account.LookupName, StringComparison.InvariantCultureIgnoreCase)))
                    continue;

                isValid = false;
                _logger?.WriteWarn(
                    $"Service account '{account.LookupName}' cannot be found in the relevant service accounts file");
            }

            isValid = role.Configs.Aggregate(isValid, (current, msiConfig) => current & PreDeploymentValidate(msiConfig, msiDirectoryLocation, parameters));

            return isValid;
        }

        private bool PreDeploymentValidate(MsiConfig msiConfig, string buildLocation, ConfigurationParameters parameters)
        {
            bool isValid = true;

            // Server roles can override the root config and they can also over ride the base transform.
            // Lets determine what is happening for this server role
            bool overridenTransform = true;
            bool overridenConfig = !string.IsNullOrWhiteSpace(parameters.OverriddenConfigName) &&
                                    !parameters.RootConfig.Equals(parameters.OverriddenConfigName, StringComparison.CurrentCultureIgnoreCase);
            string overriddenTransformName = overridenConfig ? parameters.OverriddenConfigName : parameters.EnvironmentName;

            // Look for a config transform matching the overridden config
            var transformConfigPath = Path.Combine(buildLocation, "Configuration", overriddenTransformName, msiConfig.Name);

            // If it doesnt exist, use the default transform
            if (!File.Exists(transformConfigPath))
            {
                overridenTransform = false;
                transformConfigPath = Path.Combine(buildLocation, "Configuration", "Transform", msiConfig.Name);
            }

            if (!File.Exists(transformConfigPath))
            {
                _logger?.WriteWarn(
                    $"Config file '{transformConfigPath}' cannot be found (Use overridden specific transform =  {overridenTransform})");
                return false;
            }

            // Verify every tokenised parameter is defined in the root parameters file
            var deployParams = parameters.TargetParameters.Dictionary;

            var paramsToValidate = _parameterService.GetParametersFromConfig(transformConfigPath); // use the unresolved value here

            isValid &= _parameterService.ValidateParameterList(paramsToValidate, deployParams);

            if(!isValid)
                _logger?.WriteError($"Validation failed for file '{transformConfigPath}'");

            return isValid;
        }

        public IList<ArchiveEntry> GetDeploymentFiles(MsiDeploy role, List<string> dropFolders, ConfigurationParameters parameters)
        {
            var msiFile = string.Empty;
            var dropFolder = string.Empty;

            if (role.Action == MsiAction.Uninstall)
                return null;

            // Find The msi file
            foreach(var folder in dropFolders)
            {
                msiFile = Path.Combine(folder, role.Msi.Name);
                if (!File.Exists(msiFile))
                    continue;

                dropFolder = folder;
                break;
            }

            var files = new List<ArchiveEntry>
            {
                new ArchiveEntry
                {
                    FileLocation = msiFile,
                    FileRelativePath = FileHelper.GetFileRelativePath(msiFile, dropFolder),
                    FileName = string.Empty
                }
            };

            // Find the Config files
            files.AddRange(role.Configs.Select(config => GetDeploymentFiles(config, dropFolder, parameters)));

            return files;
        }

        public bool IsMsiInstalled(PostDeployParameters parameters, MsiDeploy role, ICommandLineHelper commandLineHelper)
        {
            var msiInstalled = GetMsiInstallationStatus(parameters, role, commandLineHelper);
            return msiInstalled;
        }

        public bool IsMsiUninstalled(PostDeployParameters parameters, MsiDeploy role, ICommandLineHelper commandLineHelper)
        {
            var msiUninstalled = GetMsiInstallationStatus(parameters, role, commandLineHelper, MsiAction.Uninstall);
            return msiUninstalled;
        }

        public bool InstallPostDeploymentValidation(MsiDeploy role, PostDeployParameters parameters, string deploymentPath, string roleName)
        {
            bool isValid = true;
            IList<string> filesFailedValidation;

            _logger?.WriteLine("Checking Application Files are deployed.");
            var msiHelper = new MsiInstallerOperatorHelper(_parameterService, _logger);

            if (!msiHelper.DoConfigFilesExist(role, deploymentPath, true, out filesFailedValidation))
            {
                foreach (string file in filesFailedValidation)
                {
                    _logger?.WriteError(
                        $"{roleName} role '{role.Description}' cannot find file {file} at path {deploymentPath}.");
                }
                isValid = false;
            }

            if (parameters.TestServiceAccount == null)
            {
                _logger?.WriteLine(
                    $"MSI has not been validated for role '{role.Description}' as no test credential has been supplied.");
                return isValid;
            }

            var commandLineHelper = new CommandLineHelper(_logger);

            lock (_lock)
            {
                if (!IsMsiInstalled(parameters, role, commandLineHelper))
                {
                    _logger?.WriteError(
                        $"{roleName} role '{role.Description}' cannot validate installation exists on '{parameters.Machine.Name}'.");
                    isValid = false;
                }
            }

            return isValid;
        }

        public bool UninstallPostDeploymentValidation(MsiDeploy role, PostDeployParameters parameters, string deploymentPath, string roleName)
        {
            bool isValid;

            var commandLineHelper = new CommandLineHelper(_logger);

            if (parameters.TestServiceAccount == null)
            {
                _logger?.WriteLine(
                    $"MSI has not been validated for role '{role.Description}' as no test credential has been supplied.");
                return true;
            }

            lock (_lock)
            {
                isValid = IsMsiUninstalled(parameters, role, commandLineHelper);

                var message = isValid
                    ? $"{roleName} role '{role.Description}' uninstall has validated installation has been removed from '{parameters.Machine.Name}'."
                    : $"{roleName} role '{role.Description}' uninstall cannot validate installation has been removed from '{parameters.Machine.Name}'.";

                _logger?.WriteSummary(message, isValid ? LogResult.Success : LogResult.Fail);
            }

            return isValid;
        }

        private bool GetMsiInstallationStatus(PostDeployParameters deployParameters, MsiDeploy role, ICommandLineHelper commandLineHelper, MsiAction msiAction = MsiAction.Install)
        {
            if ((role.Msi.ProductCode == null && role.Msi.UpgradeCode == null) || (role.Msi.ProductCode == default(Guid) && role.Msi.UpgradeCode == default(Guid)))
            {
                throw new InvalidDataException("To uninstall an MSI you must at least specify an Upgrade Code or a Product Code (called Id in config).");
            }

            var paramsBuilder = new StringBuilder();

            // prepare parameters
            AddParametersForPowershellExecution(paramsBuilder, msiAction, deployParameters, role.Msi);

            // execute powershell with parameters
            var msiActionSuccessfull = ExecutePowerShellCommand(
                paramsBuilder.ToString(), deployParameters, commandLineHelper);

            return msiActionSuccessfull;
        }

        private ArchiveEntry GetDeploymentFiles(MsiConfig config, string dropFolder, ConfigurationParameters parameters)
        {
            // Server roles can override the root config and they can also over ride the base transform.
            // Lets determine what is happening for this server role
            bool overridenConfig =
                !parameters.RootConfig.Equals(parameters.OverriddenConfigName, StringComparison.CurrentCultureIgnoreCase);
            string overriddenTransformName = overridenConfig ? parameters.OverriddenConfigName : parameters.EnvironmentName;

            // Look for a config transform matching the overridden config
            var transformConfigPath = Path.Combine(dropFolder, "Configuration", overriddenTransformName, config.Name);
            var packagedName =
                $"{Path.GetFileNameWithoutExtension(config.Name)}.{overriddenTransformName}.Transform{Path.GetExtension(config.Name)}";

            // If it doesnt exist, use the default transform
            if (!File.Exists(transformConfigPath))
            {
                transformConfigPath = Path.Combine(dropFolder, "Configuration", "Transform", config.Name);
                packagedName =
                    $"{Path.GetFileNameWithoutExtension(config.Name)}.Transform{Path.GetExtension(config.Name)}";
            }

            if (!File.Exists(transformConfigPath))
            {
                throw new ApplicationException($"Config file '{transformConfigPath}' does not exist");
            }

            var archiveEntry = new ArchiveEntry
            {
                FileLocation = transformConfigPath,
                FileRelativePath = string.Empty, // create it in the root
                FileName = packagedName
            };

            return archiveEntry;
        }

        private bool ExecutePowerShellCommand(string powerShellParams, PostDeployParameters deployParameters, ICommandLineHelper commandLineHelper)
        {
            int exitCode;

            if (Environment.MachineName == deployParameters.DeploymentMachine.Name)
            {
                exitCode = commandLineHelper.PowershellCommand(powerShellParams);
            }
            else
            {
                // Removing due to poor PsExec performance in Azure. Trialling with Invoke Command
                //exitCode = commandLineHelper.PsExecCommand(
                //    deployParameters.DeploymentMachine.ExternalIpAddress,
                //    powerShellParams,
                //    deployParameters.TestServiceAccount.QualifiedUsername,
                //    deployParameters.TestServiceAccount.DecryptedPassword);

                exitCode = commandLineHelper.RemotePowershellCommand(
                    deployParameters.DeploymentMachine.ExternalIpAddress,
                    powerShellParams,
                    deployParameters.TestServiceAccount.QualifiedUsername,
                    deployParameters.TestServiceAccount.DecryptedPassword);
            }

            return exitCode == 0;
        }

        private void AddParametersForPowershellExecution(StringBuilder builder, MsiAction msiAction, PostDeployParameters parameters, Msi msi)
        {
            if (msiAction == MsiAction.Install)
            {
                builder.Append(Environment.MachineName == parameters.Machine.Name
                    ? $@"{parameters.JumpFolder}\Deployment\Scripts\MsiStatusVerification.ps1 "
                    : $@"powershell -ExecutionPolicy Unrestricted -File ""{parameters.JumpFolder}\Deployment\Scripts\MsiStatusVerification.ps1"" ");

                builder.Append($"-ComputerName \"{parameters.Machine.Name}\" ");
                builder.Append($"-MsiName \"{msi.Name}\" ");
                builder.Append($"-Driveletter \"{parameters.DriveLetter}\" ");
            }
            else
            {
                builder.Append(Environment.MachineName == parameters.Machine.Name
                    ? $@"{parameters.JumpFolder}\Deployment\Scripts\MsiStatusVerification.ps1 "
                    : $@"powershell -ExecutionPolicy Unrestricted -File ""{
                            parameters.JumpFolder
                        }\Deployment\Scripts\MsiStatusVerification.ps1"" ");

                builder.Append($"-ComputerName \"{parameters.Machine.Name}\" ");

                if(msi.UpgradeCode.HasValue)
                    builder.Append($"-UpgradeCode \"{msi.UpgradeCode.Value}\" ");

                if (msi.ProductCode.HasValue)
                    builder.Append($"-ProductCode \"{msi.ProductCode.Value}\" ");

                builder.Append($"-Driveletter \"{parameters.DriveLetter}\" ");
            }
        }
    }
}