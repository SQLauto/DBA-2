using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class MsiDeploy : BaseRole, IDeploymentRole, IPostDeploymentRole, IEquatable<MsiDeploy>
    {
        public MsiDeploy()
        {
            Dlls = new List<string>();
            Parameters = new List<Parameter>();
            Configs = new List<MsiConfig>();
            Msi = new Msi();
            Accounts = new List<ServiceAccount>();
            Action = MsiAction.Install;
            RoleType = "MSI Deploy";
        }

        public Msi Msi { get; private set; }
        public IList<ServiceAccount> Accounts { get; private set; }
        public IList<string> Dlls { get; set; }
        public IList<Parameter> Parameters { get; private set; }
        public IList<MsiConfig> Configs { get; set; }
        public MsiAction Action { get; set; }
        public bool DisableTests { get; set; }
        public bool Equals(MsiDeploy other)
        {
            return other != null
                   && Name.Equals(other.Name, StringComparison.InvariantCultureIgnoreCase)
                   && Include.Equals(other.Include, StringComparison.InvariantCultureIgnoreCase)
                   && Action.Equals(other.Action);
        }
        public string InstallationLocation {
            get
            {
                var installLocation = Parameters?.FirstOrDefault(p => p.Name.Equals("INSTALLLOCATION", StringComparison.InvariantCultureIgnoreCase));
                return installLocation?.Value;
            }
        }

        public override bool Equals(BaseRole other)
        {
            return Equals(other as MsiDeploy);
        }
    }

    [Serializable]
    public class Msi
    {
        public Guid? ProductCode { get; set; }
        public string Name { get; set; }
        public Guid? UpgradeCode { get; set; }
        public Version Version { get; set; }
    }

    [Serializable]
    public class MsiConfig
    {
        public string Name { get; set; }
        public string Target { get; set; }
        public string RelativePath => string.Concat(Target, Path.DirectorySeparatorChar, Name);
    }
}