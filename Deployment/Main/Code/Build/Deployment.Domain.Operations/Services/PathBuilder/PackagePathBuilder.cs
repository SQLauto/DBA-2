using System.IO;
using Deployment.Common.Logging;

namespace Deployment.Domain.Operations.Services
{
    public class PackagePathBuilder : DeploymentPathBuilder, IPackagePathBuilder
    {
        private readonly IDeploymentLogger _logger;

        public PackagePathBuilder(string dropFolder, IDeploymentLogger logger = null) : base(logger)
        {
            BuildDirectory = dropFolder;
            _logger = logger;
        }

        public string PublishedWebsitesRelativeDirectory => Path.Combine(BuildDirectory, "_PublishedWebsites");
        // Note this is defferent depending on whether you're using the package or deployment path builder - different number of Parents required
        public override string DeployRootDirectory => new DirectoryInfo(DeploymentRelativeDirectory).Parent.Parent.FullName;
    }
}