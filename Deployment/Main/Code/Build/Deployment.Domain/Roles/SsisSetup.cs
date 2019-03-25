using System;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class SsisSetup : BaseRole, IDeploymentRole
    {
        public SsisSetup()
        {
            RoleType = "SSIS Setup";
        }
        [Mandatory]
        public string SsisDbInstance { get; set; }
    }
}