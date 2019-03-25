using System;
using System.Collections.Generic;

namespace Deployment.Domain.Operations
{
    public interface IRootPathBuilder : IBasePathBuilder
    {
        string RootDirectory { get; set; }
        string CIRelativeDirectory { get; }
        string PostDeploymentTestsRelativeDirectory { get; }
        string PackageDirectory { get; set; }
        string PackagePreviewDirectory { get; }
        string PackageManifestFileName { get; }
        string PackageManifestFilePath { get; }
        string RigManifestFilePath { get; }

        Tuple<IDeploymentPathBuilder, IList<ICIBasePathBuilder>> CreateChildPathBuilders(string configFileName = null);
    }
}