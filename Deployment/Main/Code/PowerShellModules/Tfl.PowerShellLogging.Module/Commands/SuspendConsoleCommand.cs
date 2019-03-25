using System.Management.Automation;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsLifecycle.Suspend, "Console")]
    public class SuspendConsoleCommand : PSCmdlet
    {
        protected override void EndProcessing()
        {
            //note that this works on a per runspace basis
            HostIoInterceptor.Instance.SupressConsole = true;
        }
    }
}