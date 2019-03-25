using System.Management.Automation;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsLifecycle.Unregister, "OutputSubscriber")]
    public class UnregisterOutputSubscriberCommand : PSCmdlet
    {
        [Parameter(Mandatory = true,
            ValueFromPipeline = true,
            Position = 0)]
        public ScriptBlockOutputSubscriber InputObject { get; set; }

        [Parameter]
        public SwitchParameter NoDetachHost { get; set; }

        protected override void EndProcessing()
        {
            HostIoInterceptor.Instance.RemoveSubscribers(new [] {InputObject});

            if (!NoDetachHost)
                HostIoInterceptor.Instance.DetachFromHost();
        }
    }
}