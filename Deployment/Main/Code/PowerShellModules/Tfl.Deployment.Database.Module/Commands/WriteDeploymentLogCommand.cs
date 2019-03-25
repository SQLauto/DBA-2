using System;
using System.Collections;
using System.Management.Automation;
using Deployment.Common;
using Deployment.Database.Logging;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Database.Commands
{
    [Cmdlet(VerbsCommunications.Write, "DeploymentLog")]
    public class WriteDeploymentLogCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0)]
        [Alias("LogId", "DeployLogId", "Id", "VCloudDeploymentId")]
        public int DeploymentLogId { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNull]
        public Hashtable LogEvents { get; set; }
        [Parameter]
        public SwitchParameter VCloud { get; set; }

        protected override void ProcessRecord()
        {
            try
            {
                var dictionary = LogEvents.ToDictionary<string, object>();

                var logger = new SqlDataLogger();

                var result = VCloud
                    ? logger.LogVCloudEvent(DeploymentLogId, dictionary)
                    : logger.LogDeploymentEvent(DeploymentLogId, dictionary);

                WriteObject(result);
            }
            catch (Exception ex)
            {
                WriteError(ex, this);
            }
        }
    }
}