using System;
using System.Collections.Generic;
using System.IO;
using Deployment.Common.Logging;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class FileShareDeployOperator : IDeploymentOperator<FileShareDeploy>
    {
        private readonly IDeploymentLogger _logger;

        public FileShareDeployOperator(IParameterService parameterService,  IDeploymentLogger logger = null)
        {
            _logger = logger;
        }

        public bool PreDeploymentValidate(FileShareDeploy role, ConfigurationParameters parameters,
            List<string> outputLocations) => true;

        public IList<ArchiveEntry> GetDeploymentFiles(FileShareDeploy role, List<string> dropFolder,
            ConfigurationParameters parameters) => null;

        public bool PostDeploymentValidate(PostDeployParameters postDeployParameters, FileShareDeploy role)
        {
            var targetPath = role.TargetPath.TrimStart('\\', '/');

            bool result;

            using (var timer = new PerformanceLogger(_logger))
            {

                try
                {
                    var machineIp = postDeployParameters.Machine.DeploymentAddress;

                    var sharePath = string.Format("\\\\" + machineIp + "\\" + role.ShareName);
                    result = Directory.Exists(sharePath);

                    var message = result
                        ? $"Share '{role.ShareName}' created from {targetPath}."
                        : $"Share {role.ShareName} cannot be found. Tried to create from folder {targetPath}.";

                    timer.WriteSummary(message, result ? LogResult.Success : LogResult.Fail);

                }
                catch (Exception ex)
                {
                    timer.WriteSummary(
                        $"Unable to locate '{role.ShareName}'. Make sure {targetPath} exists.", LogResult.Error);
                    _logger?.WriteError(ex);

                    result = false;
                }
            }

            return result;
        }
    }
}