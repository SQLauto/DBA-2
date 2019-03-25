namespace Deployment.Domain.Operations
{
    public interface IPackagePathBuilder : IDeploymentPathBuilder
    {
        string PublishedWebsitesRelativeDirectory { get; }
    }
}