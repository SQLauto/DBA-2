using System.Management.Automation;
using Microsoft.ServiceBus;

namespace TFL.Deployment.ServiceBus.Commands
{
    [Cmdlet(VerbsDiagnostic.Test, "ServiceBusQueue")]
    public sealed class TestServiceBusQueueCommand : PSCmdlet
    {
        [Parameter(Position = 0, Mandatory = true)]
        public string ConnectionString { get; set; }

        [Parameter(Mandatory = true)]
        public string QueuePath { get; set; }

        protected override void ProcessRecord()
        {
            var namespaceManager = NamespaceManager.CreateFromConnectionString(ConnectionString);
            var result = namespaceManager.QueueExists(QueuePath);
            WriteObject(result);
        }
    }
}