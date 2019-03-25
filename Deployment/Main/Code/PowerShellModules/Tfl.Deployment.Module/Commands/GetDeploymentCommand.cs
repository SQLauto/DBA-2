using System;
using System.Management.Automation;
using Deployment.Domain.Operations.Services;
using Tfl.PowerShell.Common;
using Domain = Deployment.Domain;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsCommon.Get, "Deployment", DefaultParameterSetName = "New")]
    public class GetDeploymentCommand : PSCmdletBase
    {
        private string _path;

        [Parameter(Mandatory = true,
            Position = 0,
            ParameterSetName = "New")]
        [ValidateNotNullOrEmpty]
        public string Path
        {
            get { return _path; }
            set
            {
                _path = GetUnresolvedProviderPathFromPSPath(value);
            }
        }

        [Parameter(Mandatory = true,
            ParameterSetName = "New")]
        [ValidateNotNullOrEmpty]
        [Alias("Config")]
        public string Configuration { get; set; }

        [Parameter(ParameterSetName = "Existing",
           Mandatory = true,
           Position = 0,
           ValueFromPipeline = true)]
        public Domain.Deployment InputObject { get; set; }

        [Parameter(ParameterSetName = "Existing")]
        [Alias("Groups")]
        public Domain.GroupFilters GroupFilters { get; set; }

        [Parameter(ParameterSetName = "Existing")]
        public string[] Machines { get; set; }

        protected override void ProcessRecord()
        {
            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);
            var parameterService = new ParameterService(logger);
            var deploymentService = new DeploymentService(logger, parameterService);

            if (ParameterSetName.Equals("New", StringComparison.InvariantCultureIgnoreCase))
            {
                InputObject = deploymentService.GetDeployment(Path, Configuration);
            }

            if (InputObject == null)
            {
                throw new ArgumentNullException("No Deployments found for deployment configuration " + Configuration);
            }

            //filter if necessary
            if (ParameterSetName.Equals("Existing", StringComparison.InvariantCultureIgnoreCase))
            {
                InputObject = deploymentService.FilterDeployment(InputObject, Machines, GroupFilters);
            }

            WriteObject(InputObject);
        }
    }
}