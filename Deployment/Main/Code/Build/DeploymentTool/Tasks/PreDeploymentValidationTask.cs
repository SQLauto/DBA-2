using Deployment.Common;
using Deployment.Common.Logging;
using Deployment.Domain.Operations;
using Deployment.Domain.Operations.Services;

namespace Deployment.Tool.Tasks
{
    public class PreDeploymentValidation : IDeploymentToolTask
    {
        private readonly IDeploymentLogger _logger = new ConsoleLogger();
        private IRootPathBuilder _pathBuilder;

        public PreDeploymentValidation()
        {

        }

        public DeploymentTaskType TaskType => DeploymentTaskType.Pre;

        public bool ValidateInputParameters(DeploymentOperationParameters toolParameters)
        {
            if (string.IsNullOrEmpty(toolParameters.BuildLocation) || string.IsNullOrEmpty(toolParameters.DeploymentConfigFileName))
            {
                _logger?.WriteWarn("Must supply a valid config file name and build location for pre deployment validation");
                return false;
            }

            return true;
        }

        public bool TaskWork(DeploymentOperationParameters toolParameters)
        {
            var buildDirectory = toolParameters.BuildLocation;
            _pathBuilder = string.IsNullOrEmpty(buildDirectory) ? new RootPathBuilder(_logger) : new RootPathBuilder(buildDirectory, _logger);

            _logger?.WriteSummary($"Performing pre-deployment validation on config file '{toolParameters.DeploymentConfigFileName}' against build location '{_pathBuilder.RootDirectory}'");

            var paramaterService = new ParameterService(_logger);
            var validator = new DeploymentValidation(paramaterService, _logger);
            var success = validator.PreDeploymentValidation(_pathBuilder, toolParameters);

            if(success)
                _logger?.WriteLine("Pre-Validation succeeded.");
            else
                _logger?.WriteError("Pre-Validation failed.");

            return success;
        }
    }
}