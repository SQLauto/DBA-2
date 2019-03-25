using System;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class SmtpDeploy : BaseRole, IDeploymentRole, IPostDeploymentRole
    {
        public SmtpDeploy()
        {
            RoleType = "SMTP Setup and Configure";
        }
        [Mandatory]
        public string DropFolderLocation { get; set; }
        public string ForwardingMailSmtp { get; set; }

        public string FileLocation => @"Deployment\\Scripts";

        public string RelayIpFile => "RealyIpList.txt";
    }
}