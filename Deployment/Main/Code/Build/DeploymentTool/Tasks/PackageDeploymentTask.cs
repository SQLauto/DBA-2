using Deployment.Common;
using Deployment.Common.Logging;
using Deployment.Common.Xml;
using Deployment.Domain.Operations;
using Deployment.Domain.Operations.Packaging;
using Deployment.Domain.Operations.Services;

namespace Deployment.Tool.Tasks
{
    public class PackageDeploymentTask : IDeploymentToolTask
    {
        private readonly IDeploymentLogger _logger = new ConsoleLogger();
        private IRootPathBuilder _pathBuilder;

        public PackageDeploymentTask()
        {

        }

        public DeploymentTaskType TaskType => DeploymentTaskType.Package;

        public bool ValidateInputParameters(DeploymentOperationParameters toolParameters)
        {
            if (string.IsNullOrEmpty(toolParameters.BuildLocation) || string.IsNullOrEmpty(toolParameters.DeploymentConfigFileName) || string.IsNullOrEmpty(toolParameters.PackageFileName))
            {
                _logger?.WriteWarn(
                    "Must supply a valid config file name, build location and package name for packaging");
                return false;
            }

            return true;
        }

        public bool TaskWork(DeploymentOperationParameters toolParameters)
        {
            var buildDirectory = toolParameters.BuildLocation;
            _pathBuilder = string.IsNullOrEmpty(buildDirectory) ? new RootPathBuilder(_logger) : new RootPathBuilder(buildDirectory, _logger);

            if (!string.IsNullOrEmpty(toolParameters.OutputDirectory))
                _pathBuilder.PackageDirectory = _pathBuilder.OutputDirectory;
            else
                _pathBuilder.PackageDirectory = System.IO.Path.Combine(_pathBuilder.RootDirectory, "Packages");

            var pathBuilders = _pathBuilder.CreateChildPathBuilders(toolParameters.DeploymentConfigFileName);

            _logger?.WriteLine($"Performing packaging against build location '{_pathBuilder.RootDirectory}'");

            var parameterService = new ParameterService(_logger);

            var domainOperatorFactory = new DomainOperatorFactory(parameterService, _logger);
            var deploymentManifestService = new DeploymentManifestService(_pathBuilder, new XmlParserService(), _logger);

            var packagingService = new PackagingService(_pathBuilder, pathBuilders, deploymentManifestService, parameterService, _logger);
            var success = packagingService.CreateDeploymentPackage(domainOperatorFactory, toolParameters);

            if (success)
                _logger?.WriteLine($"Package '{System.IO.Path.Combine(_pathBuilder.PackageDirectory, toolParameters.PackageFileName)}' successfully created");
            else
                _logger?.WriteError($"Package '{System.IO.Path.Combine(_pathBuilder.PackageDirectory, toolParameters.PackageFileName)}' not successfully created");

            return success;
        }
    }
}