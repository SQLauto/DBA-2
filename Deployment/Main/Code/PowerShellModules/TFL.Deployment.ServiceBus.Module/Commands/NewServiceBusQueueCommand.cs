using System;
using System.Management.Automation;
using Microsoft.ServiceBus;

namespace TFL.Deployment.ServiceBus.Commands
{
    [Cmdlet(VerbsCommon.New, "ServiceBusQueue")]
    public sealed class NewServiceBusQueueCommand : PSCmdlet
    {
        [Parameter(Position = 0, Mandatory = true)]
        public string ConnectionString { get; set; }

        [Parameter(Mandatory = true)]
        public string QueuePath { get; set; }

        protected override void ProcessRecord()
        {
            var namespaceManager = NamespaceManager.CreateFromConnectionString(ConnectionString);
            if (!namespaceManager.QueueExists(QueuePath))
            {
                namespaceManager.CreateQueue(QueuePath);
                WriteVerbose(string.Format("Queue {0} created successfully", QueuePath));
                WriteObject(namespaceManager.QueueExists(QueuePath));
            }
            else
            {
                var errorMessage = string.Format("Queue {0} already exists", QueuePath);
                var invalidOperationException = new InvalidOperationException(errorMessage);

                var errorRecord = new ErrorRecord(invalidOperationException, Guid.NewGuid().ToString(), ErrorCategory.InvalidOperation, QueuePath);
                WriteVerbose(errorMessage);
                ThrowTerminatingError(errorRecord);
            }
        }
    }
}