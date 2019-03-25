using System.Collections.Generic;
using Deployment.Common;

namespace Deployment.Domain.Operations
{
    public class DeploymentOperationParameters
    {
        public DeploymentTaskType TaskType { get; set; }
        public DeploymentPlatform Platform { get; set; }
        public string RigName { get; set; }
        public string DeploymentConfigFileName { get; set; }
        public string PackageFileName { get; set; }
        public IList<string> Groups { get; set; } = new List<string>();
        public IList<string> Servers { get; set; } = new List<string>();
        public string Username { get; set; }
        public string Password { get; set; }
        public string DecryptionPassword { get; set; }
        public string PackageDeploymentAccount { get; set; }
        public bool IsDatabaseDeployment { get; set; }
        public bool IsLocalDebugMode { get; set; }
        public string JumpFolderDirectory { get; set; }
        public string ServiceAccountsFile { get; set; }
        public string BuildLocation { get; set; }
        public string OutputDirectory { get; set; }
        public string DriveLetter { get; set; }
    }
}