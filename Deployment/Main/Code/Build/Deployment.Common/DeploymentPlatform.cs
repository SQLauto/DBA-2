using System.ComponentModel;

namespace Deployment.Common
{
    public enum DeploymentPlatform
    {
        [Description("CurrentDomain")]
        CurrentDomain = 0,
        [Description("VCloud")]
        VCloud,
        [Description("Azure")]
        Azure
    }
}