using System;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class IisSetupDeploy : BaseRole, IDeploymentRole
    {
        public IisSetupDeploy(string configuration)
        {
            Configuration = configuration;
            RoleType = "IIS Setup";
        }
    }
}