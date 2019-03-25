using System;
using System.Management.Automation;
using Deployment.Installation;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsDiagnostic.Test, "IsProductInstalled", DefaultParameterSetName = "ByProduct")]
    [OutputType(typeof(bool))]
    public class TestIsProductInstalledCommand : PSCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, ParameterSetName = "ByProduct")]
        [ValidateNotNull]
        public string ProductCode { get; set; }

        [Parameter(Mandatory = true, Position = 0, ParameterSetName = "ByUpgrade")]
        [ValidateNotNull]
        public string UpgradeCode { get; set; }

        protected override void ProcessRecord()
        {
            var guid = Guid.Empty;
            var installHelper = new InstallationHelper();

            var mode = ParameterSetName == "ByProduct" ? SearchMode.ByProductCode : SearchMode.ByUpgragdeCode;

            if (ParameterSetName == "ByProduct")
            {
                 var result = Guid.TryParse(ProductCode, out guid);

                if (!result)
                    throw new InvalidCastException("ProductCode cannot be cast to a Guid");
            }

            if(ParameterSetName == "ByUpgrade")
            {
                var result = Guid.TryParse(UpgradeCode, out guid);

                if (!result)
                    throw new InvalidCastException("UpgradeCode cannot be cast to a Guid");
            }

            var exists = installHelper.IsProductInstalled(guid, mode);

            WriteObject(exists);
        }
    }
}