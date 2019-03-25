using System.Management.Automation;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsLifecycle.Resume, "Console")]
    public class ResumeConsoleCommand : PSCmdlet
    {
        protected override void EndProcessing()
        {
            //note that this works on a per runspace basis
            HostIoInterceptor.Instance.SupressConsole = false;
        }
    }
}