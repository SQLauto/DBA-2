using System.Management.Automation;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsLifecycle.Disable, "LogTimestamp")]
    public class DisableLogTimestampCommand : PSCmdlet
    {
        [Parameter(Mandatory = false, Position = 0)]
        public LogFile[] InputObject { get; set; }
        protected override void EndProcessing()
        {
            //note that suspending logging works at a runspace level
            //so when we pause, we pause for the runspace logs only.
            HostIoInterceptor.Instance.DisableLogTimestamp(InputObject);
        }
    }
}