using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Deployment.Common.Logging;

namespace Deployment.Domain.Operations.Services
{
    public class RootPathBuilder : BasePathBuilder, IRootPathBuilder
    {
        public RootPathBuilder(IDeploymentLogger logger = null)
        {
            Logger = logger;
        }

        public RootPathBuilder(string rootDirectory, IDeploymentLogger logger = null) : this(logger)
        {
            RootDirectory = rootDirectory;
            PackageDirectory = Path.Combine(RootDirectory, "Packages");
        }

        protected IDeploymentLogger Logger { get; }

        public string RootDirectory { get; set; }
        public string CIRelativeDirectory => Path.Combine(RootDirectory, "CI");
        public string PostDeploymentTestsRelativeDirectory => Path.Combine(RootDirectory, "PostDeploymentTests");
        public string PackageDirectory { get; set; }
        public string PackagePreviewDirectory { get; set; }
        public string PackageManifestFileName => "PackageManifest.xml";
        public string RigManifestFileName => "RigManifest.xml";
        public string PackageManifestFilePath => Path.Combine(PackageDirectory, PackageManifestFileName);
        public string RigManifestFilePath => Path.Combine(RootDirectory, "..", RigManifestFileName);

        public Tuple<IDeploymentPathBuilder, IList<ICIBasePathBuilder>> CreateChildPathBuilders(string configFileName = null)
        {
            var ciPathBuilders = new List<ICIBasePathBuilder>();

            //TODO: At Some point I want the Deployment CI in it's own folder. But Build Steps need changing
            var deploymentPathBuilder =
                new DeploymentPathBuilder(RootDirectory, configFileName, Logger)
                {
                    IsLocalDebugMode = IsLocalDebugMode
                };

            if (Directory.Exists(CIRelativeDirectory))
            {
                Logger?.WriteLine("Using Multi CI sources");
                ciPathBuilders.AddRange(Directory.EnumerateDirectories(CIRelativeDirectory)
                    .Select(childDirectory => new CIBasePathBuilder(childDirectory, Logger) {IsLocalDebugMode = IsLocalDebugMode}));
            }
            else
            {
                Logger?.WriteLine("Using Single CI Source");
                var ciPathBuilder = new CIBasePathBuilder(RootDirectory, Logger) {IsLocalDebugMode = IsLocalDebugMode};
                ciPathBuilders.Add(ciPathBuilder);
            }

            return new Tuple<IDeploymentPathBuilder, IList<ICIBasePathBuilder>>(deploymentPathBuilder, ciPathBuilders);
        }
    }
}