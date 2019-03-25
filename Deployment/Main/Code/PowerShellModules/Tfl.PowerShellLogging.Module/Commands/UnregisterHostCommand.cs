using System.Management.Automation;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsLifecycle.Unregister, "Host")]
    public class UnregisterHostCommand : PSCmdlet
    {
        protected override void EndProcessing()
        {
            HostIoInterceptor.Instance.DetachFromHost();
        }
    }
}