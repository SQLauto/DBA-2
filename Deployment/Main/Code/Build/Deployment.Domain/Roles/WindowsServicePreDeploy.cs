using System;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class WindowsServicePreDeploy : BaseRole, IPreDeploymentRole
    {
        public WindowsServicePreDeploy(string configuration)
        {
            Configuration = configuration;
            RoleType = "WindowsService Pre-Deploy";
        }

        [Mandatory]
        public string ServiceName { get; set; }
        public WindowsServiceStateType State { get; set; }
        public WindowsServiceActionType Action { get; set; }
    }
}