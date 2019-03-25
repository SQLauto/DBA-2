using System;
using System.Collections.Generic;
using Deployment.Common.Logging;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class MsiDeployOperator : IDeploymentOperator<MsiDeploy>
    {
        private readonly IDeploymentLogger _logger;
        private readonly MsiInstallerOperatorHelper _msiHelper;

        public MsiDeployOperator(IParameterService parameterService = null, IDeploymentLogger logger = null)
        {
            _logger = logger;
            _msiHelper = new MsiInstallerOperatorHelper(parameterService, _logger);
        }

        public bool PreDeploymentValidate(MsiDeploy role, ConfigurationParameters parameters, List<string> outputLocations)
        {
            return _msiHelper.PreDeploymentValidate(role, parameters, outputLocations);
        }

        public IList<ArchiveEntry> GetDeploymentFiles(MsiDeploy role, List<string> dropFolders, ConfigurationParameters parameters)
        {
            return _msiHelper.GetDeploymentFiles(role, dropFolders, parameters);
        }

        public bool PostDeploymentValidate(PostDeployParameters postDeployParameters, MsiDeploy role)
        {
            bool isValid;

            if (role.DisableTests)
            {
                _logger?.WriteLine(
                    $"Post deployment test is disabled for MsiDeploy role: '{role.Description}' on '{postDeployParameters.Machine.Name}'");
                return true;
            }

            var installLocation = role.InstallationLocation;

            if (role.DisableTests)
            {
                _logger?.WriteLine(
                    $"Post deployment test is disabled for MsiDeploy role: '{role.Description}' on '{postDeployParameters.Machine.Name}'");
                return true;
            }

            using (var timer = new PerformanceLogger(_logger))
            {
                try
                {
                    //Temporary until other common role files are merged
                    var deploymentPath = installLocation.Contains("{DriveLetter}:")
                        ? $@"\\{postDeployParameters.Machine.ExternalIpAddress}\{installLocation.Replace("{DriveLetter}:", $"{postDeployParameters.DriveLetter}$")}"
                        : $@"\\{postDeployParameters.Machine.ExternalIpAddress}\{installLocation.Replace(":", "$")}";

                    isValid = role.Action == MsiAction.Uninstall
                        ? _msiHelper.UninstallPostDeploymentValidation(role, postDeployParameters, deploymentPath,
                            "MsiDeploy")
                        : _msiHelper.InstallPostDeploymentValidation(role, postDeployParameters, deploymentPath,
                            "MsiDeploy");

                    timer.WriteSummary(
                        $"{role.Action} of MsiDeploy role '{role.Description}' on '{postDeployParameters.Machine.Name}' completed.", isValid ? LogResult.Success : LogResult.Fail);
                }
                catch (Exception ex)
                {
                    _logger?.WriteSummary(
                        $"{role.Action} of MSIDeploy role '{role.Description}' on '{postDeployParameters.Machine.Name}'.", LogResult.Error);
                    _logger?.WriteError(ex);

                    isValid = false;
                }
            }

            return isValid;
        }
    }
}