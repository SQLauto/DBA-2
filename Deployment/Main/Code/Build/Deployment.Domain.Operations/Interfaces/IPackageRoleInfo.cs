using System.Collections.Generic;

namespace Deployment.Domain.Operations
{
    public interface IPackageRoleInfo
    {
        IRootPathBuilder Builder { get; set; }
        System.Tuple<IDeploymentPathBuilder, IList<ICIBasePathBuilder>> PathBuilders { get; set; }
        IPackagePathBuilder PackageBuilder { get; set; }
        IDictionary<string, string> Parameters { get; set; }
        IList<string> RolesBeingDeployed { get; set; }
    }
}