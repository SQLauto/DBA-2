using System;
using System.Management.Automation;
using Deployment.Installation;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsLifecycle.Assert, "ExpectedProductCode")]
    [OutputType(typeof(bool))]
    public class AssertExpectedProductCodeCommand : PSCmdlet
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNullOrEmpty]
        public string ProductCode { get; set; }

        [Parameter(Mandatory = true)]
        [ValidateNotNull]
        public MsiKey MsiKey { get; set; }

        protected override void ProcessRecord()
        {
            var installHelper = new InstallationHelper();

            Guid guid;

            var result = Guid.TryParse(ProductCode, out guid)
                && installHelper.ValidateMsiUpgradeCode(MsiKey, guid);

            WriteObject(result);
        }
    }
}