using System.Collections.Generic;
using Deployment.Domain.Parameters;

namespace Deployment.Domain.Roles
{
    public class ConfigurationParameters
    {
        public string RootConfig { get; set; }
        public string EnvironmentName { get; set; }
        public string OverriddenConfigName { get; set; }
        public DeploymentParameters TargetParameters { get; set; }
        public IList<ServiceAccount> ServiceAccounts { get; set; }
    }
}