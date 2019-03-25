using System;
using Deployment.Common;
using Deployment.Common.Logging;
using Deployment.Domain.Operations;
using Deployment.Domain.Operations.Services;

namespace Deployment.Tool.Tasks
{
    public class PreviewDeployment : IDeploymentToolTask
    {
        private readonly AggregateLogger _logger = new AggregateLogger(new IDeploymentLogger[]{ new ConsoleLogger()});
        private IRootPathBuilder _pathBuilder;

        public PreviewDeployment()
        {
        }

        public DeploymentTaskType TaskType => DeploymentTaskType.Preview;

        public bool ValidateInputParameters(DeploymentOperationParameters toolParameters)
        {
            if (string.IsNullOrEmpty(toolParameters.DeploymentConfigFileName) || string.IsNullOrEmpty(toolParameters.PackageFileName))
            {
                _logger?.WriteWarn("You must supply values for the Config File and Package Name");
                return false;
            }

            return true;
        }

        public bool TaskWork(DeploymentOperationParameters toolParameters)
        {
            var buildDirectory = toolParameters.BuildLocation;
            _pathBuilder = string.IsNullOrEmpty(buildDirectory) ? new RootPathBuilder(_logger) : new RootPathBuilder(buildDirectory, _logger);

            //create new TextLogger for logging to file.
            var logger = new TextFileLogger(_pathBuilder.OutputDirectory, "Preview.Log");
            logger?.WriteHeader("Preview Deployment");

            //this will allow for logging to both console and file.
            _logger?.AddLogger(logger);
            _logger?.WriteLine($"Generating Config file preview for package {toolParameters.PackageFileName}");

            if (string.IsNullOrEmpty(_pathBuilder.OutputDirectory))
            {
                _pathBuilder.OutputDirectory = Environment.CurrentDirectory + "\\Output";
            }

            var previewHelper = new PreviewHelper(_logger);
            var success = previewHelper.PreviewPackage(_pathBuilder, toolParameters, toolParameters.DriveLetter);

            if (!success)
                logger?.WriteError("Failed to decrypt service account file.");

            //File.WriteAllText(toolParameters.Paths.OutputDir + "\\Preview.log", toolParameters.LogMessageBuilder.ToString());

            return success;
        }
    }
}