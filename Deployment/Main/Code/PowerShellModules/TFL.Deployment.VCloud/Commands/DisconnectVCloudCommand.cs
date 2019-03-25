using System.Management.Automation;

namespace TFL.Deployment.VCloud.Commands
{
    [Cmdlet(VerbsCommunications.Disconnect, "VCloud")]
    public class DisconnectVCloudCommand : PSCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true)]
        [ValidateNotNull]
        public IHostSubscriber InputObject { get; set; }

        protected override void ProcessRecord()
        {
            var manager = VCloudManager.Instance;

            manager.RemoveSubscriber(InputObject);

            manager.Dispose();
        }
    }
}