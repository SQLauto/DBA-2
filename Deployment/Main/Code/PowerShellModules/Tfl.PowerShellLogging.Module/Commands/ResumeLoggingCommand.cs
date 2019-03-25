using System.Management.Automation;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsLifecycle.Resume, "Logging")]
    public class ResumeLoggingCommand : PSCmdlet
    {
        [Parameter(Mandatory = false, Position = 0)]
        public LogFile[] InputObject { get; set; }

        protected override void EndProcessing()
        {
            var interceptor = HostIoInterceptor.Instance;
            interceptor.ResumeLogging(InputObject);
        }
    }
}