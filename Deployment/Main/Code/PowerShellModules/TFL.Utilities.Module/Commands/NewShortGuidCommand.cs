using System.Management.Automation;
using Deployment.Common;
using Tfl.PowerShell.Common;

namespace TFL.Utilities.Commands
{
    [Cmdlet(VerbsCommon.New, "ShortGuid")]
    public class NewShortGuidCommand : PSCmdletBase
    {
        [Parameter]
        public SwitchParameter AsString { get; set; }
        protected override void ProcessRecord()
        {
            if(AsString)
                WriteObject(ShortGuid.NewGuid().ToString());
            else
                WriteObject(ShortGuid.NewGuid());
        }
    }
}