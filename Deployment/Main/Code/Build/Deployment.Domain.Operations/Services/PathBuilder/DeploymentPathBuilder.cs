using System.IO;
using Deployment.Common.Logging;

namespace Deployment.Domain.Operations.Services
{
    public class DeploymentPathBuilder : CIBasePathBuilder, IDeploymentPathBuilder
    {
        public DeploymentPathBuilder(IDeploymentLogger logger = null) : base(logger)
        {
        }

        public DeploymentPathBuilder(string buildDirectory, IDeploymentLogger logger = null) : base(buildDirectory, logger)
        {
        }

        public DeploymentPathBuilder(string buildDirectory, string deploymentConfigFileName, IDeploymentLogger logger = null) : base(buildDirectory, logger)
        {
            DeploymentConfigFileName = deploymentConfigFileName;
        }

        public string AccountsRelativeDirectory => Path.Combine(DeploymentRelativeDirectory, "Accounts");
        public string GroupsRelativeDirectory => Path.Combine(DeploymentRelativeDirectory, "Groups");
        public string HelperScriptsRelativeDirectory => Path.Combine(DeploymentRelativeDirectory, "HelperScripts");
        public string PostDeployScriptsRelativeDirectory => Path.Combine(DeploymentRelativeDirectory, "PostDeployScripts");
        public string ScriptsRelativeDirectory => Path.Combine(DeploymentRelativeDirectory, "Scripts");
        public string SoftwareRelativeDirectory => Path.Combine(DeploymentRelativeDirectory, "Software");
        public string ToolsRelativeDirectory => Path.Combine(DeploymentRelativeDirectory, "Tools");
        public string ResourceRelativeDirectory => Path.Combine(DeploymentRelativeDirectory, "Resource");
        public string CustomConfigRelativeDirectory => Path.Combine(DeploymentRelativeDirectory, "CustomConfig");
        public string ModulesDirectory => Path.Combine(ScriptsRelativeDirectory, "Modules");
        public string FileIncludeRelativeDirectory => Path.Combine(DeploymentRelativeDirectory, "FileInclude");
        public string DeploymentConfigFileName { get; set; }
        public string DeploymentConfigFilePath => Path.Combine(ScriptsRelativeDirectory, DeploymentConfigFileName);
        public string RoleToParameterMappingsFileName => "RoleToParameterMappings.xml";
        public string RoleToParameterMappingsFilePath => Path.Combine(FileIncludeRelativeDirectory, RoleToParameterMappingsFileName);
    }
}