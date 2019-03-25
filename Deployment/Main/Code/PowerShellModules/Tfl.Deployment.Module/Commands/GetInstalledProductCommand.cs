using System;
using System.Management.Automation;
using Deployment.Installation;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsCommon.Get, "InstalledProduct")]
    [OutputType(typeof(MsiInfo))]
    public class GetInstalledProductCommand : PSCmdlet
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNull]
        public MsiKey MsiKey { get; set; }

        protected override void ProcessRecord()
        {
            var installHelper = new InstallationHelper();

            var product = installHelper.GetInstalledProduct(MsiKey);

            WriteObject(product);
        }
    }
}