using System.Management.Automation;
using Deployment.Common.Exceptions;
using Tfl.PowerShell.Common;

namespace TFL.Deployment.VCloud.Commands
{
    [Cmdlet(VerbsCommon.New, "VAppFromTemplate")]
    public class NewVAppFromTemplateCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNull]
        [Alias("Name")]
        public string RigName { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNull]
        [Alias("Template")]
        public string RigTemplate { get; set; }

        protected override void ProcessRecord()
        {
            var manager = VCloudManager.Instance;

            var vCloudService = manager.Service;
            //use a dedicated excption, or just do a write error etc.
            if (vCloudService == null || !vCloudService.Initialised)
                throw new VCloudException("VCloud service is null or not initialised.");

            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);

            var result = vCloudService.NewVAppFromTemplate(RigName, RigTemplate, logger);

            var vApp = result ? vCloudService.GetVapp(RigName) : null;

            WriteObject(vApp);
        }
    }
}