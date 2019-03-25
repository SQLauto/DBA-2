using System.Management.Automation;
using Microsoft.ServiceBus;

namespace TFL.Deployment.ServiceBus.Commands
{
    [Cmdlet(VerbsCommon.Get, "ServiceBusTopic")]
    public sealed class GetServiceBusTopicCommand : PSCmdlet
    {
        [Parameter(Mandatory = true)]
        public string ConnectionString { get; set; }

        [Parameter(Mandatory = true)]
        public string TopicPath { get; set; }

        protected override void ProcessRecord()
        {
            var namespaceManager = NamespaceManager.CreateFromConnectionString(ConnectionString);
            if (namespaceManager.TopicExists(TopicPath))
            {
                WriteVerbose(string.Format("Topic {0} exists", TopicPath));
                WriteObject(namespaceManager.GetTopic(TopicPath));
            }
            else
            {
                WriteVerbose(string.Format("Topic {0} does not exist", TopicPath));
                WriteObject(null);
            }
        }
    }
}