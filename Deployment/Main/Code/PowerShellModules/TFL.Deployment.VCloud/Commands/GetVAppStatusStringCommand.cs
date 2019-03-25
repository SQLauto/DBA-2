using System.Management.Automation;
using com.vmware.vcloud.sdk;
using Deployment.Common.Exceptions;
using Tfl.PowerShell.Common;

namespace TFL.Deployment.VCloud.Commands
{
    [Cmdlet(VerbsCommon.Get, "AppStatusString", DefaultParameterSetName = "ByApp")]
    public class GetVAppStatusStringCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0, ParameterSetName = "ByValue")]
        [ValidateNotNull]
        public int Value { get; set; }
        [Parameter(Mandatory = true, Position = 0, ParameterSetName = "ByApp", ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
        [ValidateNotNull]
        [Alias("InputObject")]
        public Vapp VApp { get; set; }
        [Parameter(Mandatory = true, Position = 0, ParameterSetName = "ByName")]
        [ValidateNotNull]
        [Alias("Name")]
        public string RigName { get; set; }

        protected override void ProcessRecord()
        {
            var manager = VCloudManager.Instance;

            var vCloudService = manager.Service;
            //use a dedicated excption, or just do a write error etc.
            if (vCloudService == null || !vCloudService.Initialised)
                throw new VCloudException("VCloud service is null or not initialised.");

            if (ParameterSetName.Equals("ByName"))
            {
                var vApp = vCloudService.GetVapp(RigName);
                Value = ((Vapp)vApp).GetVappStatus().Value();
            }
            else if (ParameterSetName.Equals("ByApp"))
            {
                Value = VApp.GetVappStatus().Value();
            }

            var result = vCloudService.ConvertVAppStatusToString(Value);

            WriteObject(result);
        }
    }
}