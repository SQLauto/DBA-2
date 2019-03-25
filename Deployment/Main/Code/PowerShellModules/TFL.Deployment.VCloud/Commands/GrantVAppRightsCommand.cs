using System.Management.Automation;
using com.vmware.vcloud.sdk;
using Deployment.Common.Exceptions;
using Tfl.PowerShell.Common;

namespace TFL.Deployment.VCloud.Commands
{
    [Cmdlet(VerbsSecurity.Grant, "VAppRights", DefaultParameterSetName = "ByApp")]
    public class GrantVAppRightsCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0, ParameterSetName = "ByApp", ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
        [ValidateNotNull]
        public Vapp VApp { get; set; }
        [Parameter(Mandatory = true, Position = 0, ParameterSetName = "ByName")]
        [ValidateNotNull]
        [Alias("Name")]
        public string RigName { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNull]
        public string[] Group { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNull]
        public string AccessLevel { get; set; }
        [Parameter]
        public SwitchParameter User { get; set; }

        protected override void ProcessRecord()
        {
            var manager = VCloudManager.Instance;

            var vCloudService = manager.Service;
            //use a dedicated excption, or just do a write error etc.
            if (vCloudService == null || !vCloudService.Initialised)
                throw new VCloudException("VCloud service is null or not initialised.");

            if (ParameterSetName.Equals("ByApp"))
            {
                vCloudService.ShareVapp(VApp, Group, AccessLevel, User.IsPresent);
            }
            else
            {
                vCloudService.ShareVapp(RigName, Group, AccessLevel, User);
            }
        }
    }
}