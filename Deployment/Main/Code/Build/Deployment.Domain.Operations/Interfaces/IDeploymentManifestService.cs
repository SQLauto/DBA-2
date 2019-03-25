using System.Xml.Linq;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations
{
    public interface IDeploymentManifestService
    {
        DeploymentManifest GetDeploymentManifest();
        bool GenerateDeploymentManifest(Domain.Deployment deployment, DeploymentServer deploymentServer, DeploymentOperationParameters parameters, string accountsDirectory);
        DeploymentManifest ParseManifestXml();
        bool UpdateDeploymentManifest(DeploymentManifest currentDeploymentManifest);
        XElement ConvertToManifestXml(DeploymentManifest manifest);
    }
}