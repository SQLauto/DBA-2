using System.Management.Automation;
using Tfl.PowerShell.Common;
using Deployment.Common.Exceptions;

namespace TFL.Deployment.VCloud.Commands
{
    [Cmdlet(VerbsCommon.Get, "VApp")]
    public class GetVAppCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNull]
        [Alias("Name")]
        public string RigName { get; set; }

        protected override void ProcessRecord()
        {
            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);

            var manager = VCloudManager.Instance;

            var vCloudService = manager.Service;

            if(vCloudService == null || !vCloudService.Initialised)
                throw new VCloudException("VCloud service is null or not initialised.");

            var vApp = vCloudService.GetVapp(RigName);
            WriteObject(vApp);
        }
    }
}