using System.Management.Automation;
using Deployment.Installation;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsDiagnostic.Test, "IsDowngradeInstallationRequest")]
    [OutputType(typeof(bool))]
    public class TestInstallationRequestIsADowngradeCommand : PSCmdlet
    {
        [Parameter(Position = 0, Mandatory = true)]
        [ValidateNotNull]
        public MsiKey MsiKey { get; set; }

        protected override void ProcessRecord()
        {
            var installHelper = new InstallationHelper();

            var result = installHelper.IsDowngradeInstallationRequest(MsiKey);

            WriteObject(result);
        }
    }
}