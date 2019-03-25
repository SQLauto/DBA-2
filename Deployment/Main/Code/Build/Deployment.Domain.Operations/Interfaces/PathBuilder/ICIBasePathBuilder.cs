namespace Deployment.Domain.Operations
{
    public interface ICIBasePathBuilder : IBasePathBuilder
    {
        string BuildDirectory { get; set; }
        string DeploymentFolder { get; }
        string DeploymentRelativeDirectory { get; }
        string ParametersRelativeDirectory { get; }
        string ExternalResourcesFolder { get; }
        string ExternalResourcesRelativeDirectory { get; }

        // New for Dynamic Config
        string UniqueEnvironmentParametersDirectory { get; }
        string PlaceholderMappingsDirectory { get; }
        string DeployRootDirectory { get; }
    }
}