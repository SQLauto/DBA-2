using System;
using System.Collections.Generic;
using System.Linq;
using System.IO;
using Deployment.Common;
using Deployment.Common.Logging;
using Deployment.Domain.Operations.DeploymentOperator;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.Services
{
    public class PostDeploymentService
    {
        private readonly IDeploymentLogger _logger;
        private readonly IRootPathBuilder _rootPathBuilder;
        private readonly Tuple<IDeploymentPathBuilder, IList<ICIBasePathBuilder>> _pathBuilders;

        public PostDeploymentService(IRootPathBuilder rootPathBuilder, Tuple<IDeploymentPathBuilder, IList<ICIBasePathBuilder>> pathBuilders, IDeploymentLogger logger = null)
        {
            _rootPathBuilder = rootPathBuilder;
            _pathBuilders = pathBuilders;
            _logger = logger;
        }

        // Validate the deployments have worked. e.g. services responding, databases present
        public bool PostDeploymentValidation(Deployment deployment, DeploymentServer deploymentServer,  DeploymentOperationParameters parameters)
        {
            var retVal = true;

            var groupsFile = $"DeploymentGroups.{deployment?.ProductGroup}.xml";
            var groupsFilePath = Path.Combine(_pathBuilders.Item1.GroupsRelativeDirectory, groupsFile);

            _logger?.WriteLine($"Validating groups against groups file {groupsFilePath}");

            var deployService = new DeploymentService(_logger);
            var groupFilters = deployService.ValidateGroups(parameters.Groups, groupsFilePath);

            groupFilters.ExcludeGroups.ForEach(g => _logger?.WriteLine($"Excluded group: {g}"));
            groupFilters.IncludeGroups.ForEach(g => _logger?.WriteLine($"Included group: {g}"));

            deployment = deployService.FilterDeployment(deployment, parameters.Servers, groupFilters);


            // Start all the windows services now to save time later during validation
            try
            {
                var serviceController = new WindowsServiceController(_logger);
                retVal &= serviceController.StartAllWindowsServices(deployment);
            }
            catch (Exception ex)
            {
                // Swallow this here, but log it. If there is an issue starting windows services, the same issue will come up in the
                // post deployment validation checks and be logged there as part of the main test
                _logger?.WriteSummary("Error starting all windows services.", LogResult.Fail);
                _logger?.WriteError(ex);
            }

            if (!retVal)
            {
                _logger?.WriteSummary("Error starting all windows services.", LogResult.Fail);
            }

            var factory = new DomainOperatorFactory(null, _logger);
            var postDeploymentOperator = new UniversalValidationOperator(factory, _logger);
            var serviceAccounts = GetServiceAccounts(parameters.DecryptionPassword, deployment.Environment);

            foreach (var machine in deployment.Machines.Where(m=>m.PostDeploymentRoles.Any()))
            {
                _logger?.WriteLine($"Executing post deployment roles on machine {machine.Name}");

                var postDeployParameters = CreatePostDeployParameters(deployment, machine, deploymentServer, serviceAccounts, parameters.Platform, parameters.DriveLetter);

                foreach (dynamic role in machine.PostDeploymentRoles)
                {
                    try
                    {
                        PerformanceLogger performanceLogger;
                        using (performanceLogger = new PerformanceLogger(_logger) { TestName = role.Description })
                        {
                            performanceLogger.TestResult =
                                postDeploymentOperator.PostDeploymentValidate(role, postDeployParameters);

                            performanceLogger.WriteSummary($"{performanceLogger.TestName} on {machine.Name}.", performanceLogger.TestResult ? LogResult.Success : LogResult.Fail);
                        }

                        retVal &= performanceLogger.TestResult;
                    }
                    catch (Exception ex)
                    {
                        _logger?.WriteError(ex);
                        retVal = false;
                    }
                }
            }

            var testOperator = new UniversalCustomTestOperator(_logger);

            foreach (var machine in deployment.Machines.Where(m=>m.CustomTestRoles.Any()))
            {
                var postDeployParameters = CreatePostDeployParameters(deployment, machine, deploymentServer, serviceAccounts, parameters.Platform, parameters.DriveLetter);

                foreach (var customTest in machine.CustomTestRoles)
                {
                    PerformanceLogger result;
                    using (result = new PerformanceLogger(_logger))
                    {
                        result.TestResult = testOperator.RunTest(customTest, machine, postDeployParameters);

                        result.WriteSummary($"{customTest.Name} on {machine.Name}.", result.TestResult ? LogResult.Success : LogResult.Fail);
                    }

                    retVal &= result.TestResult;
                }
            }

            return retVal;
        }

        private IList<ServiceAccount> GetServiceAccounts(string decryptionPassword, string environment)
        {
            var serviceAccountsFileName = $"{environment}.ServiceAccounts.xml";
            var serviceAccountsFile = Path.Combine(_pathBuilders.Item1.AccountsRelativeDirectory, serviceAccountsFileName);
            var serviceAccountsManager = new ServiceAccountsManager(decryptionPassword, _logger);
            return serviceAccountsManager.ParseFile(serviceAccountsFile);
        }

        private PostDeployParameters CreatePostDeployParameters(Deployment deployment, Machine machine, DeploymentServer deploymentServer, IList<ServiceAccount> serviceAccounts, DeploymentPlatform targetPlatform, string driveLetter)
        {
            var parameters = new PostDeployParameters(machine)
            {
                Environment = deployment.Environment,
                JumpFolder = $@"{driveLetter}:\Deploy\DropFolder",
                ServiceAccounts = serviceAccounts,
                TargetPlatform = targetPlatform,
                DriveLetter = driveLetter,
                DeploymentMachine = deploymentServer,
                TestServiceAccount = serviceAccounts.FirstOrDefault(
                    a =>
                        a.LookupName.Equals(deployment.PostDeploymentTestIdentity,
                            StringComparison.InvariantCultureIgnoreCase))
            };


            return parameters;
        }
    }
}