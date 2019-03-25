using System.Collections.Generic;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class UniversalPackageOperator
    {
        private readonly IDomainOperatorFactory _operatorFactory;

        public UniversalPackageOperator(IDomainOperatorFactory operatorFactory)
        {
            _operatorFactory = operatorFactory;
        }

        public IEnumerable<ArchiveEntry> GetDeploymentFiles<T>(T role, List<string> dropFolders, ConfigurationParameters parameters) where T : IBaseRole
        {
            return _operatorFactory.GetOperator<T>()?.GetDeploymentFiles(role, dropFolders, parameters);
        }
    }
}