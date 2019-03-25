using System;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class AspNetStateServiceDeploy : BaseRole, IDeploymentRole, IPostDeploymentRole
    {
        public AspNetStateServiceDeploy(string configuration)
        {
            Configuration = configuration;
            RoleType = "ASP.Net State Service Deploy";
        }
    }
}