using System;
using System.Management.Automation;
using Microsoft.ServiceBus;
using Microsoft.ServiceBus.Messaging;

namespace TFL.Deployment.ServiceBus.Commands
{
    [Cmdlet(VerbsCommon.New, "ServiceBusSubscription")]
    public sealed class NewServiceBusSubscriptionCommand : PSCmdlet
    {
        [Parameter(Position = 0, Mandatory = true)]
        public string ConnectionString { get; set; }

        [Parameter(Mandatory = true)]
        public string TopicPath { get; set; }

        [Parameter(Mandatory = true)]
        public string SubscriptionName { get; set; }

        [Parameter(Mandatory = false)]
        public int? MaxDeliveryCount { get; set; }

        protected override void ProcessRecord()
        {
            var namespaceManager = NamespaceManager.CreateFromConnectionString(ConnectionString);
            if (!namespaceManager.SubscriptionExists(TopicPath, SubscriptionName))
            {
                var description = new SubscriptionDescription(TopicPath, SubscriptionName);

                if (MaxDeliveryCount.HasValue) description.MaxDeliveryCount = MaxDeliveryCount.Value;

                namespaceManager.CreateSubscription(description);
                WriteVerbose(string.Format("Subscription {0} on Topic {1} created successfully", SubscriptionName, TopicPath));
                WriteObject(namespaceManager.SubscriptionExists(TopicPath, SubscriptionName));
            }
            else
            {
                var errorMessage = string.Format("Subscription {0} on Topic {1} already exists", SubscriptionName, TopicPath);
                var invalidOperationException = new InvalidOperationException(errorMessage);

                var errorRecord = new ErrorRecord(invalidOperationException, Guid.NewGuid().ToString(), ErrorCategory.InvalidOperation, TopicPath);
                WriteVerbose(errorMessage);
                WriteError(errorRecord);
                ThrowTerminatingError(errorRecord);
            }
        }
    }
}