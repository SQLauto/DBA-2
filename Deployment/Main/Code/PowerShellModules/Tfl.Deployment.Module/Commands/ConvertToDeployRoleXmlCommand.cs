using System.Management.Automation;
using Deployment.Common.Logging;
using Deployment.Domain.Operations;
using Deployment.Domain.Operations.Services;
using Domain = Deployment.Domain;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsData.ConvertTo, "DeployRoleXml")]
    public class ConvertToDeployRoleXmlCommand : PSCmdlet
    {
        [Parameter(Mandatory = true,
           Position = 0,
           ValueFromPipeline = true)]
        [ValidateNotNull]
        public Domain.Roles.IBaseRole InputObject { get; set; }

        protected override void ProcessRecord()
        {
            var manager = new DeploymentService(NullLogger.Instance);
            var xml = manager.ConvertDeployRoleToXml(InputObject);

            WriteObject(xml);
        }
    }
}