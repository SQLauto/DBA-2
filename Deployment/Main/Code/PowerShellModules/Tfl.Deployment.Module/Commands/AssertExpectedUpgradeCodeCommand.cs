using System;
using System.Management.Automation;
using Deployment.Installation;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsLifecycle.Assert, "ExpectedUpgradeCode")]
    [OutputType(typeof(bool))]
    public class AssertExpectedUpgradeCodeCommand : PSCmdlet
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNull]
        public string UpgradeCode { get; set; }

        [Parameter(Mandatory = true)]
        [ValidateNotNull]
        public MsiKey MsiKey { get; set; }

        protected override void ProcessRecord()
        {
            var installHelper = new InstallationHelper();

            Guid guid;

            var result = Guid.TryParse(UpgradeCode, out guid)
                && installHelper.ValidateMsiUpgradeCode(MsiKey, guid);

            WriteObject(result);
        }
    }
}