using System.Management.Automation;
using Deployment.Database.Logging;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Database.Commands
{
    [Cmdlet(VerbsCommon.New, "DeploymentLogId")]
    public class NewDeploymentLogIdCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNullOrEmpty]
        [Alias("VAppName")]
        public string RigName { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNullOrEmpty]
        [Alias("ScriptHost")]
        public string ComputerName { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string ScriptName { get; set; }
        [Parameter]
        [Alias("Notes")]
        [PSDefaultValue(Value="")]
        public string PackageName { get; set; }
        [Parameter]
        public SwitchParameter VCloud { get; set; }

        protected override void ProcessRecord()
        {
            var sqlDataLogger = new SqlDataLogger();

            var deploymentLogId = VCloud
                ? sqlDataLogger.GenerateVCloudDeploymentId(RigName, PackageName, ComputerName, ScriptName)
                : sqlDataLogger.GenerateDeploymentId(RigName, PackageName, ComputerName, ScriptName);

            WriteObject(deploymentLogId);
        }
    }
}