using System.IO;
using Deployment.Common.Logging;

namespace Deployment.Domain.Operations.Services
{
    public class CIBasePathBuilder : BasePathBuilder, ICIBasePathBuilder
    {
        public CIBasePathBuilder(IDeploymentLogger logger = null)
        {
            Logger = logger;
        }

        public CIBasePathBuilder(string buildDirectory, IDeploymentLogger logger = null) : this(logger)
        {
            BuildDirectory = buildDirectory;
        }

        protected IDeploymentLogger Logger { get; }
        public string BuildDirectory { get; set; }
        public string DeploymentFolder => IsLocalDebugMode ? string.Empty : "Deployment";
        public string DeploymentRelativeDirectory => Path.Combine(BuildDirectory, DeploymentFolder);
        public string ParametersRelativeDirectory => Path.Combine(DeploymentRelativeDirectory, "Parameters");
        public string ExternalResourcesFolder => "ExternalResources";
        public string ExternalResourcesRelativeDirectory => Path.Combine(BuildDirectory, ExternalResourcesFolder);
        public string UniqueEnvironmentParametersDirectory => Path.Combine(DeploymentRelativeDirectory, @"DynamicConfig\UniqueEnvironmentConfig");
        public string PlaceholderMappingsDirectory => Path.Combine(DeploymentRelativeDirectory, @"DynamicConfig\PlaceholderMappings");

        // Argh: Parent.Parent works for the local Dev unit test invocations
        // Running live this works for deployment but the Functional tests are looking one level too high
        // Local build folders must be wrong
        public virtual string DeployRootDirectory => new DirectoryInfo(DeploymentRelativeDirectory).Parent.FullName;
    }
}