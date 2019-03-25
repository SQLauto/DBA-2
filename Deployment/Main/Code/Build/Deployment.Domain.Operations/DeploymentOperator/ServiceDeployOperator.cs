using System;
using System.Collections.Generic;
using System.Linq;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class ServiceDeployOperator : IDeploymentOperator<ServiceDeploy>
    {
        private readonly IDeploymentLogger _logger;
        private readonly MsiInstallerOperatorHelper _msiHelper;

        public ServiceDeployOperator(IParameterService parameterService = null, IDeploymentLogger logger = null)
        {
            var ps = parameterService ?? new ParameterService(logger);
            _logger = logger;
            _msiHelper = new MsiInstallerOperatorHelper(ps, _logger);
        }

        public bool PreDeploymentValidate(ServiceDeploy role, ConfigurationParameters parameters, List<string> outputLocations)
        {
            var isValid = _msiHelper.PreDeploymentValidate(role.MsiDeploy, parameters, outputLocations);

            foreach (var service in role.Services)
            {
                if (parameters.ServiceAccounts.Any(s => s.LookupName.Equals(service.Account.LookupName, StringComparison.InvariantCultureIgnoreCase)))
                    continue;

                isValid = false;
                _logger?.WriteWarn(
                    $"Service account '{service.Account.LookupName}' cannot be found in the relevant service accounts file");
            }

            return isValid;
        }

        public IList<ArchiveEntry> GetDeploymentFiles(ServiceDeploy role, List<string> dropFolders, ConfigurationParameters parameters)
        {
            return _msiHelper.GetDeploymentFiles(role.MsiDeploy, dropFolders, parameters);
        }

        public bool PostDeploymentValidate(PostDeployParameters parameters, ServiceDeploy role)
        {
            bool isValid;

            if (role.DisableTests || parameters.DisablePostDeploymentTests)
            {
                _logger?.WriteLine(
                    $"Post deployment tests are disabled for ServiceDeploy role: '{role.Description}' on '{parameters.Machine.Name}'");
                return true;
            }

            using (var timer = new PerformanceLogger(_logger))
            {
                try
                {
                    isValid = role.Action == MsiAction.Uninstall
                        ? UninstallPostDeploymentValidation(role, parameters)
                        : InstallPostDeploymentValidation(role, parameters);
                }
                catch (Exception ex)
                {
                    _logger?.WriteError(ex);
                    isValid = false;
                }

                timer.WriteSummary(
                    $"{role.Action} of ServiceDeploy role '{role.Description}' on '{parameters.Machine.Name}'.", isValid ? LogResult.Success : LogResult.Fail);
            }

            return isValid;
        }

        private bool InstallPostDeploymentValidation(ServiceDeploy role, PostDeployParameters parameters)
        {
            var commandLineHelper = new CommandLineHelper(_logger);

            var isValid = _msiHelper.IsMsiInstalled(parameters, role.MsiDeploy, commandLineHelper);

            var controller = new WindowsServiceController(_logger);

            foreach (var service in role.Services.Where(s => !s.DisableTests))
            {
                var waitTime = TimeSpan.FromMilliseconds(service.VerificationWaitTimeMilliSeconds);
                if (!controller.IsServiceAvailableAndRunning(service.Name, parameters.Machine.Name, parameters.Machine.ExternalIpAddress, waitTime))
                {
                    isValid = false;
                }
            }

            return isValid;
        }


        private bool UninstallPostDeploymentValidation(ServiceDeploy role, PostDeployParameters parameters)
        {
            var controller = new WindowsServiceController(_logger);

            // Check each Windows Service has been removed
            var isValid = role.Services.Where(s => !s.DisableTests).Aggregate(true, (current, service) =>
                current & !controller.HasServiceBeenRemoved(service.Name, parameters.Machine.Name,
                    parameters.Machine.ExternalIpAddress));

            var commandLineHelper = new CommandLineHelper(_logger);

            isValid &= _msiHelper.IsMsiUninstalled(parameters, role.MsiDeploy, commandLineHelper);

            return isValid;
        }
    }
}
