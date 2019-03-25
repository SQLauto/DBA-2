using System;
using System.Collections.Generic;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class FileShareDeploy : BaseRole, IDeploymentRole, IPostDeploymentRole
    {
        public FileShareDeploy(string configuration)
        {
            Users = new List<FileShareUser>();
            Configuration = configuration;
            RoleType = "FileShare Creation";
        }
        [Mandatory]
        public string ShareName { get; set; }
        [Mandatory]
        public string TargetPath { get; set; }
        public IList<FileShareUser> Users { get; set; }
        public FileShareAction Action { get; set; }
    }

    [Serializable]
    public class FileShareUser
    {
        [Mandatory]
        public string Name { get; set; }
        public FileSharePermission Permissions { get; set; }
        public FileShareUserAccountType AccountType { get; set; }
    }

    public enum FileSharePermission
    {
        Read = 0,
        Change,
        Full
    }

    public enum FileShareAction
    {
        Create = 0,
        Change,
        Remove
    }

    public enum FileShareUserAccountType
    {
        DomainAccount = 0,
        ServiceAccount
    }
}