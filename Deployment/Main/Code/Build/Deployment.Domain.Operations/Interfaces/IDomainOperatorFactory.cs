using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations
{
    public interface IDomainOperatorFactory
    {
        IDeploymentOperator<T> GetOperator<T>() where T : IBaseRole;
    }
}