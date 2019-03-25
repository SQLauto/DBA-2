using System;
using System.Management.Automation;
using Deployment.Installation;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsCommon.Get, "InstalledProducts")]
    [OutputType(typeof(MsiInfo[]))]
    public class GetInstalledProductsCommand : PSCmdlet
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNull]
        public string UpgradeCode { get; set; }

        protected override void ProcessRecord()
        {
            Guid guid;
            var result = Guid.TryParse(UpgradeCode, out guid);

            if (!result)
                throw new InvalidCastException("UpgradeCode cannot be cast to a Guid");

            var installHelper = new InstallationHelper();

            var products = installHelper.GetInstalledProducts(guid);

            WriteObject(products);
        }
    }
}