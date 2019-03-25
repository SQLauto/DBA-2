using System.Collections.Generic;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations
{
    public interface IDeploymentOperator<in T> where T : IBaseRole
    {
        bool PreDeploymentValidate(T role, ConfigurationParameters parameters, List<string> outputLocations);

        bool PostDeploymentValidate(PostDeployParameters postDeployParameters, T role);
        IList<ArchiveEntry> GetDeploymentFiles(T role, List<string> dropFolders, ConfigurationParameters parameters);
    }
}