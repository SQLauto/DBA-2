using System.Management.Automation;
using Deployment.Common.Logging;
using Deployment.Domain.Operations.Services;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsCommon.Get, "DeploymentGroupFilters")]
    public class GetDeploymentGroupFiltersCommand : PSCmdlet
    {
        [Parameter(
             Position = 0,
             ValueFromPipeline = true,
             ValueFromPipelineByPropertyName = true)]
        public string[] Groups { get; set; }

        [Parameter]
        [ValidateNotNullOrEmpty]
        [Alias("Path", "FilePath")]
        public string XmlPath { get; set; }

        protected override void ProcessRecord()
        {
            var utility = new DeploymentService(NullLogger.Instance);

            var groupFilters = utility.ValidateGroups(Groups, XmlPath);
            WriteObject(groupFilters);
        }
    }
}