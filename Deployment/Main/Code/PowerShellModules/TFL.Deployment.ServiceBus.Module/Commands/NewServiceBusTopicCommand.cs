using System;
using System.Management.Automation;
using Microsoft.ServiceBus;

namespace TFL.Deployment.ServiceBus.Commands
{
    [Cmdlet(VerbsCommon.New, "ServiceBusTopic")]
    public sealed class NewServiceBusTopicCommand : PSCmdlet
    {
        [Parameter(Position = 0, Mandatory = true)]
        public string ConnectionString { get; set; }

        [Parameter(Mandatory = true)]
        public string TopicPath { get; set; }

        protected override void ProcessRecord()
        {
            var namespaceManager = NamespaceManager.CreateFromConnectionString(ConnectionString);
            if (!namespaceManager.TopicExists(TopicPath))
            {
                namespaceManager.CreateTopic(TopicPath);
                WriteVerbose(string.Format("Topic {0} created successfully", TopicPath));
                WriteObject(namespaceManager.TopicExists(TopicPath));
            }
            else
            {
                var errorMessage = string.Format("Topic {0} already exists", TopicPath);
                var invalidOperationException = new InvalidOperationException(errorMessage);

                var errorRecord = new ErrorRecord(invalidOperationException, Guid.NewGuid().ToString(), ErrorCategory.InvalidOperation, TopicPath);
                WriteVerbose(errorMessage);
                WriteError(errorRecord);
                ThrowTerminatingError(errorRecord);
            }
        }
    }
}