using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations
{
    public struct CommonRoleInfo
    {
        public CommonRoleInfo(IBaseRole commonRole, IDomainModelFactory factory)
        {
            CommonRole = commonRole;
            Factory = factory;
        }

        public IBaseRole CommonRole { get; }
        public IDomainModelFactory Factory { get; }
    }
}