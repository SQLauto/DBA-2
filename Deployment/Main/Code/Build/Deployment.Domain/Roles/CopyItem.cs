using System;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class CopyItem : BaseRole, IFileSystemRole, IDeploymentRole
    {
        public CopyItem()
        {
            RoleType = "Copy Item Deploy";
        }

        [Mandatory]
        public string Source { get; set; }
        [Mandatory]
        public string Target { get; set; }
        [Mandatory]
        public bool Recurse { get; set; }
        [Mandatory]
        public string Filter { get; set; }
        [Mandatory]
        public bool Replace { get; set; }
        public bool IsAbsolutePath { get; set; }
    }
}