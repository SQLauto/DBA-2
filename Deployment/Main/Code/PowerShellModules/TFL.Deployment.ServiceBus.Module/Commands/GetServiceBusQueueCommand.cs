using System.Management.Automation;
using Microsoft.ServiceBus;

namespace TFL.Deployment.ServiceBus.Commands
{
    [Cmdlet(VerbsCommon.Get, "ServiceBusQueue")]
    public sealed class GetServiceBusQueueCommand : PSCmdlet
    {
        [Parameter(Mandatory = true)]
        public string ConnectionString { get; set; }

        [Parameter(Mandatory = true)]
        public string QueuePath { get; set; }

        protected override void ProcessRecord()
        {
            var namespaceManager = NamespaceManager.CreateFromConnectionString(ConnectionString);
            if (namespaceManager.QueueExists(QueuePath))
            {
                WriteVerbose(string.Format("Queue {0} exists", QueuePath));
                WriteObject(namespaceManager.GetQueue(QueuePath));
            }
            else
            {
                WriteVerbose(string.Format("Queue {0} does not exist", QueuePath));
                WriteObject(null);
            }
        }
    }
}