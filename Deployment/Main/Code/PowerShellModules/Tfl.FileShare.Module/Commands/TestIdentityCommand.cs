using System.Management.Automation;
using Deployment.Common.Security;

namespace Tfl.FileShare.Commands
{
    [Cmdlet(VerbsDiagnostic.Test, "Identity")]
    public class TestIdentityCommand : PSCmdlet
    {
        [Parameter(Mandatory = true,
           Position = 0,
           ValueFromPipeline = true)]
        [ValidateNotNull]
        public string Name { get; set; }

        [Parameter]
        public SwitchParameter PassThru { get; set; }

        protected override void ProcessRecord()
        {
            var identity = Identity.FindByName(Name);

            if (identity == null)
            {
                WriteObject(false);
                return;
            }

            if(PassThru)
                WriteObject(identity);
            else
                WriteObject(true);
        }
    }
}