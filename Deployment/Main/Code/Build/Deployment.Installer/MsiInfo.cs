using System;
using Microsoft.Deployment.WindowsInstaller;

namespace Deployment.Installation
{
    [Serializable]
    public class MsiInfo
    {
        private MsiInfo()
        {
        }

        public MsiInfo(ProductInstallation installation, MsiKey key)
        {
            ProductName = installation.ProductName ?? string.Empty;
            Publisher = installation.Publisher ?? string.Empty;
            InstallDate = installation.InstallDate;
            InstallLocation = installation.InstallLocation ?? string.Empty;
            LocalPackage = installation.LocalPackage ?? string.Empty;
            IsInstalled = true;

            Key = key ?? new MsiKey(null, installation.ProductCode, installation.ProductVersion);
        }

        public MsiKey Key { get; set; }
        public string ProductName { get; set; }
        public string Publisher { get; set; }
        public DateTime InstallDate { get; set; }
        public string InstallLocation { get; set; }
        public string LocalPackage { get; set; }
        public bool IsInstalled { get; set; }
        public bool IsDowngrade { get; set; }

        public override string ToString()
        {
            return
                Key?.ToString() ?? (ProductName ?? string.Empty);
        }

        public static MsiInfo Empty => new MsiInfo();
    }
}
