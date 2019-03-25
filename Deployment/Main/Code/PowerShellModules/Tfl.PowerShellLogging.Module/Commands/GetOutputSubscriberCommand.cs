
using System.Management.Automation;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsCommon.Get, "OutputSubscriber")]
    public class GetOutputSubscriberCommand : PSCmdlet
    {
        protected override void EndProcessing()
        {
            var interceptor = HostIoInterceptor.Instance;

            foreach (var subscriber in interceptor.Subscribers)
            {
                var scriptBlockSubscriber = subscriber as ScriptBlockOutputSubscriber;
                if (scriptBlockSubscriber != null)
                {
                    WriteObject(scriptBlockSubscriber);
                }
            }
        }
    }
}