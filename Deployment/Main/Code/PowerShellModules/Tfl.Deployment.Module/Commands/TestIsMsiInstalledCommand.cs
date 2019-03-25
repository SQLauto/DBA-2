using System;
using System.Management.Automation;
using Deployment.Installation;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsDiagnostic.Test, "IsMsiInstalled", DefaultParameterSetName = "ByKey")]
    [OutputType(typeof(bool))]
    public class TestIsMsiInstalledCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0, ParameterSetName = "ByKey")]
        [ValidateNotNull]
        public MsiKey MsiKey { get; set; }

        [Parameter(Mandatory = true, Position = 0, ParameterSetName = "ByValues")]
        [ValidateNotNull]
        public string UpgradeCode { get; set; }

        [Parameter(Mandatory = true, ParameterSetName = "ByValues")]
        [ValidateNotNull]
        public string ProductCode { get; set; }

        [Parameter(Mandatory = true, ParameterSetName = "ByValues")]
        [ValidateNotNull]
        public Version ProductVersion { get; set; }

        protected override void ProcessRecord()
        {
            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);
            var installHelper = new InstallationHelper(logger);

            var msiKey = MsiKey;

            if (ParameterSetName == "ByValues")
            {
                Guid upgradeCode;
                var result = Guid.TryParse(UpgradeCode, out upgradeCode);

                if(!result)
                    WriteError(new ArgumentException($"UpgradeCode {UpgradeCode} cannot be cast to a Guid"), this, ErrorCategory.InvalidArgument, true);

                Guid productCode;
                result = Guid.TryParse(ProductCode, out productCode);

                if (!result)
                    WriteError(new ArgumentException($"ProductCode {ProductCode} cannot be cast to a Guid"), this, ErrorCategory.InvalidArgument, true);

                msiKey = new MsiKey(upgradeCode, productCode, ProductVersion);
            }

            var installed = installHelper.GetInstalledProduct(msiKey);

            WriteHost(installed.IsInstalled ? "Product is currenlty installed with that MsiKey" : "Proudct is not currently installed.");

            WriteObject(installed.IsInstalled);
        }
    }
}