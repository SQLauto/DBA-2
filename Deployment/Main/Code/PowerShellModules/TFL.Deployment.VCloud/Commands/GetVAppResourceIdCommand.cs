using System.Management.Automation;
using com.vmware.vcloud.sdk;
using Deployment.Common.Exceptions;

namespace TFL.Deployment.VCloud.Commands
{
    [Cmdlet(VerbsCommon.Get, "VAppResourceId", DefaultParameterSetName = "ByApp")]
    public class GetVAppResourceIdCommand : PSCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, ParameterSetName = "ByApp",
            ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
        [ValidateNotNull]
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
                VApp = (Vapp)vCloudService.GetVapp(RigName);
            }

            var guid = VApp.Resource.id.TrimStart("urn:vcloud:vapp:".ToCharArray());
            WriteObject(guid);
        }
    }
}