using System;
using System.Management.Automation;
using Deployment.Installation;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsCommon.Get, "InstallPathForProductCode")]
    public class GetInstallPathForProductCodeCommand : PSCmdlet
    {
        [Parameter(Mandatory = true,Position = 0)]
        [ValidateNotNull]
        public string ProductCode { get; set; }

        protected override void ProcessRecord()
        {
            Guid guid;
            var result = Guid.TryParse(ProductCode, out guid);

            if(!result)
                throw new InvalidCastException("TODO");

            var installHelper = new InstallationHelper();

            var path = installHelper.GetInstallLocationFromProductCode(guid);

            WriteObject(path);
        }
    }
}