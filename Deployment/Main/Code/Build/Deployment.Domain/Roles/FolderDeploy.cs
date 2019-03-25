using System;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class FolderDeploy : BaseRole, IFileSystemRole, IDeploymentRole
    {
        public FolderDeploy()
        {
            Action = DeploymentAction.Unknown;
            RoleType = "FileSystem Folder Deploy";
        }

        [Mandatory]
        public DeploymentAction Action { get; set; }

        [Mandatory]
        public string TargetPath { get; set; }
        public bool IsAbsolutePath { get; set; }
    }

    public enum DeploymentAction
    {
        Unknown = 0,
        Install,
        Uninstall
    }
}