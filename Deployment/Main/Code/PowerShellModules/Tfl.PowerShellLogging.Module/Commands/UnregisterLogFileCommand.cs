using System.Management.Automation;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsLifecycle.Unregister, "LogFile")]
    public class UnregisterLogFileCommand : PSCmdlet
    {
        [Parameter(Mandatory = true,
            ValueFromPipeline = true,
            Position = 0)]
        public LogFile[] InputObject { get; set; }

        [Parameter]
        public SwitchParameter NoDetachHost { get; set; }

        protected override void ProcessRecord()
        {
            HostIoInterceptor.Instance.RemoveSubscribers(InputObject);

            if (!NoDetachHost)
                HostIoInterceptor.Instance.DetachFromHost();
        }
    }
}