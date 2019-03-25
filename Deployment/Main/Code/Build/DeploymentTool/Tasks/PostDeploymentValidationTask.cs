using System.Linq;
using System.IO;
using Deployment.Common;
using Deployment.Common.Logging;
using Deployment.Domain.Operations;
using Deployment.Domain.Operations.Services;

namespace Deployment.Tool.Tasks
{
    public class PostDeploymentValidationTask : IDeploymentToolTask
    {
        private readonly AggregateLogger _logger = new AggregateLogger(new IDeploymentLogger[] { new ConsoleLogger() });

        public PostDeploymentValidationTask()
        {

        }

        public DeploymentTaskType TaskType => DeploymentTaskType.Post;

        public bool ValidateInputParameters(DeploymentOperationParameters toolParameters)
        {
            if (string.IsNullOrEmpty(toolParameters.DeploymentConfigFileName))
            {
                _logger?.WriteWarn("Must supply a valid config file name for post deployment validation");
                return false;
            }

            return true;
        }

        public bool TaskWork(DeploymentOperationParameters toolParameters)
        {
            var rootDirectory = Directory.GetParent(Directory.GetParent(toolParameters.DeploymentConfigFileName).FullName).FullName;

            var loggingDirectory =
                string.IsNullOrEmpty(toolParameters.OutputDirectory) ?
                System.Reflection.Assembly.GetExecutingAssembly().Location :
                toolParameters.OutputDirectory;

            //create new TextLogger for logging to file.
            var summaryLogger = new TextFileLogger(loggingDirectory, "Summary.PostDeploymentTest.log");
            var logger = new TextFileLogger(loggingDirectory, "PostDeploymentTest.log", summaryLogger);

            //this will allow for logging to both console and file.
            _logger?.AddLogger(logger);
            logger?.WriteHeader(toolParameters.DeploymentConfigFileName, true);

            var pathBuilder = new RootPathBuilder(rootDirectory, _logger)
            {
                IsLocalDebugMode = true,
                LoggingDirectory = loggingDirectory
            };

            _logger?.WriteLine(
                $"Performing post deployment validation in the current domain against config file '{toolParameters.DeploymentConfigFileName}'\r\n");

            var paramaterService = new ParameterService(_logger);

            var validator = new DeploymentValidation(paramaterService, _logger);

            var result = validator.PostDeploymentValidation(pathBuilder, toolParameters);

            _logger?.WriteSummary("");
            _logger?.WriteSummary(result ? "All Tests Passed Validation": "Tests failed.");

            return result;
        }
    }
}
