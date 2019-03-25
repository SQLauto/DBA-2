using System;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class WebServicePostDeploy : BaseRole, IPostDeploymentRole
    {
        public WebServicePostDeploy(string configuration)
        {
            Configuration = configuration;
            Timeout = 30;
            RoleType = "WebService Post-Deploy";
        }

        [Mandatory]
        public int PortNumber { get; set; }
        //[Mandatory]
        public string WebServicePath { get; set; }
        public int Timeout { get; set; }

    }
}