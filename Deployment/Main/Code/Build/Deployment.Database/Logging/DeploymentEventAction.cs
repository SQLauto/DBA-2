using System.ComponentModel;

namespace Deployment.Database.Logging
{
    public enum DeploymentEventAction
    {
        None = 0,
        [Description("SetupDeployment_Start")]
        BeginSetupDeployment = 1,
        [Description("SetupDeployment_End")]
        EndSetupDeployment = 2,
        [Description("DeployRig_Start")]
        BeginDeployRig = 3,
        [Description("DeployRig_End")]
        EndDeployRig = 4,
        [Description("PostTestShutdown_Start")]
        BeginPostTestShutdown = 5,
        [Description("PostTestShutdown_End")]
        EndPostTestShutdown = 6
    }
}