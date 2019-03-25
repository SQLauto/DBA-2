using System.Management.Automation;
using Microsoft.ServiceBus;

namespace TFL.Deployment.ServiceBus.Commands
{
    [Cmdlet(VerbsCommon.Get, "ServiceBusSubscription")]
    public sealed class GetServiceBusSubscriptionCommand : PSCmdlet
    {
        [Parameter(Mandatory = true)]
        public string ConnectionString { get; set; }

        [Parameter(Mandatory = true)]
        public string TopicPath { get; set; }

        [Parameter(Mandatory = true)]
        public string SubscriptionName { get; set; }

        protected override void ProcessRecord()
        {
            var namespaceManager = NamespaceManager.CreateFromConnectionString(ConnectionString);
            if (namespaceManager.SubscriptionExists(TopicPath, SubscriptionName))
            {
                WriteVerbose(string.Format("Subscription {0} on Topic {1} exists", SubscriptionName, TopicPath));
                WriteObject(namespaceManager.GetSubscription(TopicPath, SubscriptionName));
            }
            else
            {
                WriteVerbose(string.Format("Subscription {0} on Topic {1} does not exists", SubscriptionName, TopicPath));
                WriteObject(null);
            }
        }
    }
}