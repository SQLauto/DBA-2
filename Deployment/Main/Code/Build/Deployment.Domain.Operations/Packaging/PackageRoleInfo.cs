using System.Collections.Generic;

namespace Deployment.Domain.Operations.Packaging
{
    public class PackageRoleInfo : IPackageRoleInfo
    {
        public IRootPathBuilder Builder { get; set; }
        public System.Tuple<IDeploymentPathBuilder, IList<ICIBasePathBuilder>> PathBuilders { get; set; }
        public IPackagePathBuilder PackageBuilder { get; set; }
        public IList<string> RolesBeingDeployed { get; set; }
        public IDictionary<string, string> Parameters { get; set; }
    }
}