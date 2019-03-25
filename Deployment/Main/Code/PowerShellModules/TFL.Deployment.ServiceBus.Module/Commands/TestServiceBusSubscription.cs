using System.Management.Automation;
using Microsoft.ServiceBus;

namespace TFL.Deployment.ServiceBus.Commands
{
    [Cmdlet(VerbsDiagnostic.Test, "ServiceBusSubscription")]
    public sealed class TestServiceBusSubscriptionCommand : PSCmdlet
    {
        [Parameter(Position = 0, Mandatory = true)]
        public string ConnectionString { get; set; }

        [Parameter(Mandatory = true)]
        public string TopicPath { get; set; }

        [Parameter(Mandatory = true)]
        public string SubscriptionName { get; set; }

        protected override void ProcessRecord()
        {
            var namespaceManager = NamespaceManager.CreateFromConnectionString(ConnectionString);
            var result = namespaceManager.SubscriptionExists(TopicPath, SubscriptionName);
            WriteObject(result);
        }
    }
}