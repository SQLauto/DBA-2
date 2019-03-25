using System.Management.Automation;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsLifecycle.Enable, "LogTimestamp")]
    public class EnableLogTimestampCommand : PSCmdlet
    {
        [Parameter(Mandatory = false, Position = 0)]
        public LogFile[] InputObject { get; set; }
        protected override void EndProcessing()
        {
            HostIoInterceptor.Instance.EnableLogTimestamp(InputObject);
        }
    }
}