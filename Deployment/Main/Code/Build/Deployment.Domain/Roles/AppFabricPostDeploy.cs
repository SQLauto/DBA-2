using System;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class AppFabricPostDeploy : BaseRole, IPostDeploymentRole
    {
        public AppFabricPostDeploy(string configuration)
        {
            Configuration = configuration;
            RoleType = "AppFabric Post-Deploy";
        }

        [Mandatory]
        public int PortNumber { get; set; }
        public AppFabricStateType State { get; set; }
        public WindowsServiceActionType Action { get; set; }
    }

    public enum AppFabricStateType
    {
        Up = 0,
        Down,
    }
}