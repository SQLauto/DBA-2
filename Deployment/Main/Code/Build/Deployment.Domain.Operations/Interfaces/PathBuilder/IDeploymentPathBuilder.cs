namespace Deployment.Domain.Operations
{
    public interface IDeploymentPathBuilder : ICIBasePathBuilder
    {
        string AccountsRelativeDirectory { get; }
        string GroupsRelativeDirectory { get; }
        string HelperScriptsRelativeDirectory { get; }
        string PostDeployScriptsRelativeDirectory { get; }
        string ScriptsRelativeDirectory { get; }
        string SoftwareRelativeDirectory { get; }
        string ToolsRelativeDirectory { get; }
        string ResourceRelativeDirectory { get; }
        string CustomConfigRelativeDirectory { get; }
        string ModulesDirectory { get; }
        string FileIncludeRelativeDirectory { get; }
        string DeploymentConfigFileName { get; set; }
        string DeploymentConfigFilePath { get; }
        string RoleToParameterMappingsFileName { get; }
        string RoleToParameterMappingsFilePath { get; }
    }
}