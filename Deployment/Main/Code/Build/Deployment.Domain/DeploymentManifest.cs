using System.Collections.Generic;

namespace Deployment.Domain
{
    public class DeploymentManifest
    {
        public DeploymentManifest()
        {
            Deployments = new List<DeploymentInfo>();
        }

        public IList<DeploymentInfo> Deployments { get; }

        public string RootPath { get; set; } = @"D:\Deploy";
    }

    public class DeploymentInfo
    {
        public DeploymentInfo()
        {
            PackageInfo = new PackageInfo();
            ServerInfo = new DeploymentServerInfo();
            AccountInfo = new DeploymentAccountInfo();
        }

        public PackageInfo PackageInfo { get; set; }
        public DeploymentServerInfo ServerInfo { get; set; }
        public DeploymentAccountInfo AccountInfo { get; set; }
        public int Index { get; set; }
        public bool IsDatabaseDeployment { get; set; }
    }

    public class DeploymentServerInfo
    {
        public string Name { get; set; }
        public string ExternalIP { get; set; }
        //only used in production environments (currently)
        public string DeploymentTempPath { get; set; }
    }

    public class PackageInfo
    {
        public string Name { get; set; }
        public string Config { get; set; }
        public string Environment { get; set; }
        public IList<string> Groups { get; set; } = new List<string>();
        public IList<string> Servers { get; set; } = new List<string>();
    }

    public class DeploymentAccountInfo
    {
        public string Name { get; set; }
        public string Password { get; set; }
    }
}