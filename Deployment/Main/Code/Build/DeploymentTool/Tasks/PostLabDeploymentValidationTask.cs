using System.Threading;
using System.IO;
using Deployment.Common;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Common.Settings;
using Deployment.Domain.Operations;
using Deployment.Domain.Operations.Services;

namespace Deployment.Tool.Tasks
{
    public class PostLabDeploymentValidationTask : IDeploymentToolTask
    {
        private readonly AggregateLogger _logger = new AggregateLogger(new IDeploymentLogger[] { new ConsoleLogger() });

        public PostLabDeploymentValidationTask()
        {
        }

        public DeploymentTaskType TaskType => DeploymentTaskType.PostLab;

        public bool ValidateInputParameters(DeploymentOperationParameters toolParameters)
        {
            if (string.IsNullOrEmpty(toolParameters.RigName) || string.IsNullOrEmpty(toolParameters.DeploymentConfigFileName))
            {
                _logger?.WriteWarn("Must supply a valid config file name and rig name for post deployment validation against a virtual platform");
                return false;
            }

            if(!File.Exists(toolParameters.DeploymentConfigFileName))
            {
                _logger?.WriteWarn("Must supply a valid config file path for post deployment validation against a virtual platform");
                return false;
            }

            return true;
        }

        public bool TaskWork(DeploymentOperationParameters toolParameters)
        {
            var rootDirectory = Directory.GetParent(Directory.GetParent(toolParameters.DeploymentConfigFileName).FullName).FullName;

            var loggingDirectory = 
                string.IsNullOrEmpty(toolParameters.OutputDirectory) ?
                Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) :
                toolParameters.OutputDirectory;
            //create new TextLogger for logging to file.
            var summaryLogger = new TextFileLogger(loggingDirectory, "Summary.PostDeploymentTest.log");
            var logger = new TextFileLogger(loggingDirectory, "PostDeploymentTest.log", summaryLogger);

            //this will allow for logging to both console and file.
            logger?.WriteHeader(toolParameters.RigName);
            _logger?.AddLogger(logger);

            var pathBuilder = new RootPathBuilder(rootDirectory, _logger)
            {
                IsLocalDebugMode = true,
                LoggingDirectory = loggingDirectory
            };

            var targetPlatform = PostDeploymentTestSettings.TargetPlatform;

            _logger?.WriteLine(
                $"Running post deployment validation against rig '{toolParameters.RigName}' in '{targetPlatform}' for config file '{toolParameters.DeploymentConfigFileName}'");

            var parameterService = new ParameterService(_logger);

            var validator = new DeploymentValidation(parameterService, _logger);

            var result = validator.PostDeploymentValidation(pathBuilder, toolParameters);

            _logger?.WriteSummary("");
            _logger?.WriteSummary(result ? "All Tests Passed Validation" : "Tests failed.");

            return result;
        }
    }
}