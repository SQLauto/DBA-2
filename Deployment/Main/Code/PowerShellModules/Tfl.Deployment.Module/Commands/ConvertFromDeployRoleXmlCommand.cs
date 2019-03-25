using System;
using System.Management.Automation;
using Deployment.Common.Logging;
using Deployment.Domain.Operations.Services;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsData.ConvertFrom, "DeployRoleXml")]
    public class ConvertFromDeployRoleXmlCommand :PSCmdlet
    {
        [Parameter(Mandatory = true,
           Position = 0,
           ValueFromPipeline = true)]
        [ValidateNotNull]
        public string SourceXml { get; set; }

        [Parameter]
        public Type Type { get; set; }

        protected override void ProcessRecord()
        {
            var manager = new DeploymentService(NullLogger.Instance);
            var role = manager.ConverXmlToDeployRole(SourceXml, Type);

            WriteObject(role);
        }
    }
}