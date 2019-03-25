using System.Collections.Generic;
using Deployment.Common.Logging;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class StateServiceOperator : IDeploymentOperator<AspNetStateServiceDeploy>
    {
        private readonly IDeploymentLogger _logger;

        public StateServiceOperator(IParameterService parameterService = null, IDeploymentLogger logger = null)
        {
            _logger = logger;
        }

        public bool PreDeploymentValidate(AspNetStateServiceDeploy role, ConfigurationParameters parameters, List<string> outputLocation) => true;

        public bool PostDeploymentValidate(PostDeployParameters postDeployParameters, AspNetStateServiceDeploy role)
        {
            var serviceController = new WindowsServiceController(_logger);

            var isValid = serviceController.IsServiceAvailableAndRunning("aspnet_state", postDeployParameters.Machine.Name,
                postDeployParameters.Machine.DeploymentAddress, postDeployParameters.ServiceWaitTime, false);

            return isValid;
        }

        public IList<ArchiveEntry> GetDeploymentFiles(AspNetStateServiceDeploy role, List<string> dropFolders, ConfigurationParameters parameters) => null;
    }
}