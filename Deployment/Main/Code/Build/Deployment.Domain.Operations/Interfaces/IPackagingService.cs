using Deployment.Domain.Operations.Packaging;

namespace Deployment.Domain.Operations
{
    public interface IPackagingService
    {
        bool CreateDeploymentPackage(IDomainOperatorFactory operatorFactory, DeploymentOperationParameters parameters);
        PackageRoleInfo CreatePackageRoleInfo(Domain.Deployment deployment);
    }
}