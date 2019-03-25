using System.Management.Automation;
using Deployment.Common.Exceptions;
using Tfl.PowerShell.Common;

namespace TFL.Deployment.VCloud.Commands
{
    [Cmdlet(VerbsCommon.Set, "FirewallConfig")]
    public class SetVAppFirewallConfigCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNull]
        [Alias("Name")]
        public string RigName { get; set; }
        [ValidateNotNull]
        [Parameter]
        public bool SetupFirewall { get; set; }

        protected override void ProcessRecord()
        {
            var manager = VCloudManager.Instance;

            var vCloudService = manager.Service;

            if (vCloudService == null || !vCloudService.Initialised)
            {
                throw new VCloudException("VCloud service is null or not initialised");
            }

            var result = vCloudService.FirewallConfiguration(RigName, SetupFirewall);
            
            WriteObject(result);
        }
    }
}
