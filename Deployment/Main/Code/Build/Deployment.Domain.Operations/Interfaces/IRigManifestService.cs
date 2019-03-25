using Deployment.Domain.Parameters;

namespace Deployment.Domain.Operations
{
    public interface IRigManifestService
    {
        RigManifest ReadRigManifest (string parameterFile);

        RigManifest GetRigManifest(IDeploymentPathBuilder packagePathBuilder);
    }
}
