using System.Management.Automation;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsLifecycle.Suspend, "Logging")]
    public class SuspendLoggingCommand : PSCmdlet
    {
        [Parameter(Mandatory = false, Position = 0)]
        public LogFile[] InputObject { get; set; }

        protected override void EndProcessing()
        {
            //note that suspending logging works at a runspace level
            //so when we pause, we pause for the runspace logs only.
            var interceptor = HostIoInterceptor.Instance;
            interceptor.SuspendLogging(InputObject);
        }
    }
}
