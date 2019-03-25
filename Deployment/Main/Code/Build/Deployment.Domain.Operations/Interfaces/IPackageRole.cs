using System.Collections.Generic;
using Deployment.Common.Logging;

namespace Deployment.Domain.Operations
{
    public interface IPackageRole
    {
        bool PreDeploymentValidate( List<string> outputLocations, IDeploymentLogger logger);
        IList<ArchiveEntry> GetDeploymentFiles();
        bool HasWorkToDo();
        IPackageRoleInfo RoleInfo { get; set; }
    }
}