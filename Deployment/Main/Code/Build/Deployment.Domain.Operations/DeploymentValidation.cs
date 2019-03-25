using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Deployment.Common;
using Deployment.Common.Exceptions;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Common.Xml;
using Deployment.Domain.Operations.DeploymentOperator;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Roles;
using Deployment.Domain.Operations.Packaging;
using Deployment.Domain.Parameters;

namespace Deployment.Domain.Operations
{
    public class DeploymentValidation
    {
        private readonly IDeploymentLogger _logger;
        private readonly IParameterService _parameterService;

        public DeploymentValidation(IParameterService parameterService, IDeploymentLogger logger)
        {
            if (parameterService == null)
            {
                throw new ArgumentNullException(nameof(parameterService));
            }
            _parameterService = parameterService;
            _logger = logger;
        }

        // Run pre deployment validation checks on the deployment 'package'
        public bool PreDeploymentValidation(IRootPathBuilder pathBuilder, DeploymentOperationParameters operationParameters)
        {
            var isValid = true;

            var blockTimer = new PerformanceLogger(_logger);
            try
            {
                var pathBuilders = pathBuilder.CreateChildPathBuilders(operationParameters.DeploymentConfigFileName);

                var deployService = new DeploymentService(_logger, _parameterService);
                var validator = new DomainModelValidator(_logger);
                var factoryBuilder = new DomainModelFactoryBuilder();

                var deployment = deployService.GetDeployment(validator, factoryBuilder, pathBuilders.Item1, pathBuilders.Item2);

                isValid &= validator.ValidationResult.Result;

                _logger?.WriteLine($"Deployment object created: {isValid}");
                _logger?.WriteLine($"Unfiltered machine count: {deployment?.Machines?.Count ?? 0}");

                if (!isValid)
                {
                    validator.ValidationResult.ValidationErrors.ForEach(e => _logger?.WriteWarn(e));
                }

                var placeholderFilePath =
                    Path.Combine(pathBuilders.Item1.PlaceholderMappingsDirectory, $"{deployment?.Configuration}.PlaceholderMappings.xml");

                PlaceholderMappings mappings = new PlaceholderMappings();
                if (File.Exists(placeholderFilePath))
                {
                    _logger?.WriteLine("Placeholder Mappings file found");

                    //Doing this so I don't have to replicate code
                   var dynamicConfigParamService = new ParameterService(_logger);
                   mappings = dynamicConfigParamService.GetPlaceholderMappings(pathBuilders.Item1,
                        deployment?.Configuration);
                }
                
                var groupsFile = $"DeploymentGroups.{deployment?.ProductGroup}.xml";
                
                var groupsFilePath = Path.Combine(pathBuilders.Item1.GroupsRelativeDirectory, groupsFile);

                _logger?.WriteLine($"Validating groups against groups file {groupsFilePath}");

                var groupFilters = deployService.ValidateGroups(operationParameters.Groups, groupsFilePath);

                groupFilters.ExcludeGroups.ForEach(g => _logger?.WriteLine($"Excluded group: {g}"));
                groupFilters.IncludeGroups.ForEach(g => _logger?.WriteLine($"Included group: {g}"));

                deployment = deployService.FilterDeployment(deployment, operationParameters.Servers, groupFilters);

                _logger?.WriteLine($"Filtered machine count: {deployment.Machines.Count}");

                if (deployment.Machines.Count == 0)
                {
                    _logger?.WriteWarn(
                        "No machines were found for filtered deployment. This will result in an uncessary package. Check your config.");
                }

                //pathBuilder.SetServiceAccountsPath(deployment.Environment);
                var serviceAccountFile = $"{deployment?.Environment}.ServiceAccounts.xml";
                var serviceAccountFilePath = Path.Combine(pathBuilders.Item1.AccountsRelativeDirectory, serviceAccountFile);
                var serviceAccountsManager =
                    new ServiceAccountsManager(operationParameters.DecryptionPassword, _logger);

                var accounts = serviceAccountsManager.ParseFile(serviceAccountFilePath);

                var configParamService = new ConfigurationParameterService(_parameterService, pathBuilders.Item1, pathBuilders.Item2);
                var factory = new DomainOperatorFactory(_parameterService, _logger);
                var packageOperator = new UniversalValidationOperator(factory, _logger);
                var outputLocations = (pathBuilders.Item2.Cast<CIBasePathBuilder>()
                    .Select(ciPathBuilder => ciPathBuilder.BuildDirectory)).ToList();

                outputLocations.Add(pathBuilders.Item1.BuildDirectory);

                foreach (var machine in deployment.Machines)
                {
                    _logger?.WriteLine($"Running pre-deployment validation for machine {machine.Name}");

                    foreach (dynamic role in machine.AllRoles())
                    {
                        var parameters = configParamService.BuildConfigurationParameters(deployment, role, accounts);

                        CheckMappingsAreCorrect(parameters, mappings);

                        isValid &= packageOperator.PreDeploymentValidate(role, parameters, outputLocations,
                            machine.DeploymentAddress);
                    }
                }

                //TODO: Do dependencies work.
                //var dependancies = GetWindowServices(deployment);
                //var services = dependancies.SelectMany(k => k.Value).Where(s => s != null).ToList();
                //var serviceDependancies =
                //    services.SelectMany(s => s.Services).SelectMany(d => d.DependsUponServices);

                //foreach (var dependancy in serviceDependancies)
                //{
                //    //dependancy across multiple machines is this correct?
                //    //validate that my simplification is correct
                //    if (dependancies.ContainsKey(dependancy.TargetMachines.First()))
                //    {
                //        var targetdependancies = dependancies[dependancy.TargetMachines.First()];
                //        var dependentService =
                //            targetdependancies.SelectMany(d => d.Services)
                //                .FirstOrDefault(s => s.Name == dependancy.ServiceName);
                //        if (dependentService == null)
                //        {
                //            _logBuilder.AppendLine(
                //                string.Format("Error: Dependent Service {1} on Machine '{0}' is not being deployed",
                //                    dependancy.TargetMachines.First(), dependancy.ServiceName));
                //            isValid = false;
                //        }
                //        else
                //        {
                //            //Log Error Service with Dependency target machine does not exits
                //            _logBuilder.AppendLine(
                //                string.Format(
                //                    "Error: TargetMachine '{0}' is not declared or is not being deployed for Service '{1}'",
                //                    dependancy.TargetMachines.First(), dependancy.ServiceName));
                //            isValid = false;
                //        }
                //    }
                //}

                //var jumpDirectory = string.IsNullOrEmpty(operationParameters.JumpFolderDirectory) ? @"D:\Deploy\DropFolder" : operationParameters.JumpFolderDirectory;
                var deploymentManifestService = new DeploymentManifestService(pathBuilder, new XmlParserService(), _logger);
                var packageRoleInfo =
                    new PackagingService(pathBuilder, pathBuilders, deploymentManifestService, _parameterService, _logger).CreatePackageRoleInfo(deployment);
                var packageCommand = new PackageRoleCommand(packageRoleInfo);

                isValid &= packageCommand.PreDeploymentValidate(outputLocations, _logger);
            }
            catch (ValidationException ex)
            {
                foreach (var error in ex.ValidationErrors)
                {
                    _logger?.WriteWarn(error);
                }

                isValid = false;
            }
            catch (Exception ex)
            {
                _logger?.WriteError(ex);
                isValid = false;
            }
            finally
            {
                blockTimer.WriteSummary("Finished running Pre-Deployment validation.", isValid ? LogResult.Success : LogResult.Fail);
                blockTimer.Dispose();
                _logger?.WriteHeader("Completed Pre-Deployment Validation", true);
            }

            return isValid;
        }

        public bool PostDeploymentValidation(IRootPathBuilder rootPathBuilder, DeploymentOperationParameters operationParameters)
        {
            var retVal = true;

            _logger?.WriteLine($"Using Platform: {operationParameters.Platform}");

            using (var blockTimer = new PerformanceLogger(_logger))
            {
                try
                {
                    var pathBuilders = rootPathBuilder.CreateChildPathBuilders(Path.GetFileName(operationParameters.DeploymentConfigFileName));

                    var result = GetDeploymentObject(pathBuilders, operationParameters.Groups,
                        operationParameters.Servers, operationParameters.Platform, operationParameters.DeploymentConfigFileName, operationParameters.RigName,
                        rootPathBuilder.RigManifestFilePath);

                    if (!result.Item1)
                        return false;

                    var deployment = result.Item2;
                    if(rootPathBuilder.IsLocalDebugMode)
                    {
                        using (var netUserHelper = new NetUseHelper(_logger))
                        {
                            foreach (var machine in result.Item2.Machines)
                            {
                                netUserHelper.CreateMappedDrive(machine.Name, machine.ExternalIpAddress, "D$", null, operationParameters.Username, operationParameters.Password);
                            }
                        }
                    }

                    /* Commented out by SB [09/08/17] as we fell it is no longer needed. To be removed at later date
                    retVal &= MachinesAccessibiltyTest(result.Item3.Name, result.Item3.ExternalIpAddress,
                        deployment.Machines);

                    if (!retVal)
                        return false;
                    */

                    _logger?.WriteLine("Starting Post-Deployment role validation");
                    var postDeploymentService = new PostDeploymentService(rootPathBuilder, pathBuilders, _logger);

                    retVal &=
                        postDeploymentService.PostDeploymentValidation(deployment, result.Item3, operationParameters);

                    blockTimer.WriteSummary(
                        "Post-Deployment Validation complete.", retVal ? LogResult.Success : LogResult.Fail);

                    if (rootPathBuilder.IsLocalDebugMode)
                    {
                        using (var netUserHelper = new NetUseHelper(_logger))
                        {
                            netUserHelper.DeleteMappedDrive(result.Item3.Name, result.Item3.ExternalIpAddress, "D$");
                        }
                    }

                }
                catch (Exception ex)
                {
                    blockTimer.WriteSummary(
                        "An exception occured during Post-Deployment Validation. Please check detailed log for information.",
                        LogResult.Fail);
                    _logger?.WriteError(ex);

                    retVal = false; // Need to log failure on exception - PDVT is passing even when exception is thrown
                }
                /* Commented out by SB [09/08/17] as we fell it is no longer needed. To be removed at later date
                finally
                {
                    if(operationParameters.RemoveMappings)
                        CleanUpMappings(deployment, operationParameters.DriveLetter);
                }
                */
            }

            _logger?.WriteHeader(
                $"Completed Post-Deployment Validation for platform {operationParameters.Platform}", true);

            return retVal;
        }

        private Tuple<bool, Deployment, DeploymentServer> GetDeploymentObject(Tuple<IDeploymentPathBuilder, IList<ICIBasePathBuilder>> pathBuilders,
            IList<string> groups, IList<string> servers, DeploymentPlatform targetPlatform, string configFilePath, string rigName, string rigManifestFilePath)
        {
            var result = true;

            Domain.Deployment deployment;
            DeploymentServer deploymentMachine;

            using (var timer = new PerformanceLogger(_logger))
            {
                _logger?.WriteLine("Setting up Post-Deployment Test Conditions.");

                var deploymentService = new DeploymentService(_logger, _parameterService);

                _logger?.WriteLine("Building Deployment model.");

                deployment = deploymentService.GetDeployment(new DomainModelValidator(_logger), new DomainModelFactoryBuilder(), pathBuilders.Item1, pathBuilders.Item2);

                var rmService = new RigManifestService(_logger);
                var rigManifest = rmService.GetRigManifest(pathBuilders.Item1);

                result &= AssignIpAddressesToMachines(deployment, rigManifest);

                deploymentMachine = new DeploymentServer(deployment.Machines.FirstOrDefault(m => m.DeploymentMachine));

                var deploymentGroupsFile = Path.Combine(pathBuilders.Item1.GroupsRelativeDirectory, $"DeploymentGroups.{deployment.ProductGroup}.xml");

                try
                {
                    var groupFilters = deploymentService.ValidateGroups(groups, deploymentGroupsFile);
                    deployment = deploymentService.FilterDeployment(deployment, servers, groupFilters);

                    _logger?.WriteSummary($"Completed creation of Deployment model '{deployment.Name}'",
                        LogResult.Success);
                }
                catch (FileNotFoundException)
                {
                    _logger?.WriteSummary($"Unable to find deployments group file: [{deploymentGroupsFile}]",
                        LogResult.Fail);
                    result = false;
                }
                catch (ArgumentNullException)
                {
                    _logger?.WriteSummary("Invalid groups specified. Failing Post-Deployment.", LogResult.Fail);
                    result = false;
                }

                //if (result)
                //{
                //    _logger?.WriteLine($"Setting service accounts file using configuration {deployment.Environment}");
                //    var serviceAccountFile = $"{deployment?.Environment}.ServiceAccounts.xml";
                //    var serviceAccountFilePath = Path.Combine(pathBuilders.Item1.AccountsRelativeDirectory, serviceAccountFile);
                //}

                timer.WriteSummary(
                    "Set up of Post-Deployment test conditions completed.", result ? LogResult.Success : LogResult.Fail);
            }

            return Tuple.Create(result, deployment, deploymentMachine);
        }

        private bool AssignIpAddressesToMachines(Domain.Deployment deployment, RigManifest rigManifest) //string rigManifestFilePath)
        {
            _logger?.WriteLine("Assigning External IP Addresses.");

            bool success = true;
            var externalIPAddresses = new Dictionary<string, string>();
            foreach (var machine in rigManifest.Dictionary)
            {
                var name = machine.Key;
                if (!string.IsNullOrEmpty(name))
                {
                    externalIPAddresses.Add(name, machine.Value);
                }
            }
            foreach (var machine in deployment.Machines)
            {
                if (!externalIPAddresses.ContainsKey(machine.Name))
                {
                    success = false;
                    _logger?.WriteWarn($"Unable to obtain external IP address for machine: [{machine.Name}]");
                }
                else
                {
                    machine.ExternalIpAddress = externalIPAddresses[machine.Name];
                }
            }

            return success;
        }

        private void CheckMappingsAreCorrect(ConfigurationParameters parameters, PlaceholderMappings mappings)
        {
            var startIdentifier = "#_";
            var endIdentifier = "_#";            
            var targetParams = parameters.TargetParameters;

            if (mappings.Dictionary.Count == 0)
            {
                return;
            }

            var mappingsList = mappings.Dictionary.Keys;
                foreach (var param in targetParams.Dictionary)
                {
                    var paramValue = param.Value.Text;
                    if (paramValue.Contains(startIdentifier) && paramValue.Contains(endIdentifier))
                    {
                        if (!mappingsList.Any(s => paramValue.Contains(s)))
                        {
                            _logger?.WriteError($"A placeholder {paramValue} has been found in parameters but it not in the placeholder file");
                            return;
                        }
                    }
                }
        }

        private bool TestNetUse(DeploymentServer deploymentServer, Domain.Deployment deployment, string username, string password, string driveLetter)
        {
            var retVal = true;

            // parallelising this section might be the cause of some vcloud connections issues so keep it non parallel for now
            using (var timer = new PerformanceLogger(_logger))
            {
                using (var netUseHelper = new NetUseHelper(_logger))
                {
                    foreach (var machine in deployment.Machines.Where(m => !m.Name.Equals(deploymentServer.Name) && m.DeploymentRoles.Any()))
                    {
                        // Ensure credentials are cached for cross domain connections. Do this here once and one time only for machines containing
                        // windows services or create folders because these are the types of deployment that we can only validate cross domain with net use
                        retVal &= netUseHelper.CreateMappedDrive(machine.Name, machine.ExternalIpAddress, $"{driveLetter}$", null, username, password);

                        //Thread.Sleep(1000); //Review need for this
                    }
                }

                //no need to map deployment server
                //foreach (var machine in deployment.Machines.Where(m => !m.Name.Equals(deploymentServer.Name) && m.DeploymentRoles.Any()))
                //{
                //    // Ensure credentials are cached for cross domain connections. Do this here once and one time only for machines containing
                //    // windows services or create folders because these are the types of deployment that we can only validate cross domain with net use
                //    retVal &= commmandLineHelper.CreateMappedDrive(machine.Name, machine.ExternalIpAddress, string.Empty, "D$", username, password);

                //    Thread.Sleep(5000); //Review need for this
                //}

                timer.WriteSummary("'net use' tests completed.", retVal ? LogResult.Success : LogResult.Fail);
            }

            _logger?.WriteLine(string.Empty);

            return retVal;
        }

        private bool CleanUpMappings(Domain.Deployment deployment, string driveLetter)
        {
            bool retVal;

            if (deployment == null)
                return true;

            using (var netUseHelper = new NetUseHelper(_logger))
            {
                retVal = deployment.Machines.Where(m => m.DeploymentRoles.Any())
                    .Aggregate(true, (current, machine) => current & netUseHelper.DeleteMappedDrive(machine.Name, machine.ExternalIpAddress, $"{driveLetter}$"));
            }

            return retVal;
        }
    }
}