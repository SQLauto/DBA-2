using System;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class WindowsServicePostDeploy : BaseRole, IPostDeploymentRole
    {
        public WindowsServicePostDeploy(string configuration)
        {
            Configuration = configuration;
            RoleType = "WindowsService Post-Deploy";
        }

        [Mandatory]
        public string ServiceName { get; set; }
        public WindowsServiceStateType State { get; set; }
        public WindowsServiceActionType Action { get; set; }
    }
}