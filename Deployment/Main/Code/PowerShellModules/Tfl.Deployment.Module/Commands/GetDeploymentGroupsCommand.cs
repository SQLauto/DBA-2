using System.Management.Automation;
using Deployment.Common.Logging;
using Deployment.Domain.Operations.Services;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsCommon.Get, "DeploymentGroups")]
    public class GetDeploymentGroupsCommand : PSCmdlet
    {
        [Parameter(
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true)]
        [ValidateNotNullOrEmpty]
        [Alias("Path", "FilePath")]
        public string XmlPath { get; set; }

        protected override void ProcessRecord()
        {
            var utility = new DeploymentService(NullLogger.Instance);

            var groups = utility.ParseGroups(XmlPath);
            WriteObject(groups);
        }
    }
}