using System.Management.Automation;
using Deployment.Common.Helpers;
using Tfl.PowerShell.Common;

namespace TFL.Utilities.Commands
{
    [Cmdlet(VerbsCommon.New, "MappedDrive")]
    public class NewMappedDriveCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNull]
        public string ComputerIpAddress { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNull]
        public string ComputerName { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNull]
        public string ShareName { get; set; }
        [Parameter]
        public string Device { get; set; }
        [Parameter]
        public PSCredential Credential { get; set; }

        [Parameter]
        public SwitchParameter Force { get; set; }

        protected override void ProcessRecord()
        {
            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);

            using (var netUseHelper = new NetUseHelper(logger))
            {
                var result = Credential != null
                    ? netUseHelper.CreateMappedDrive(ComputerName, ComputerIpAddress, ShareName, Device, Credential.UserName,
                        Credential.GetNetworkCredential().Password, Force.IsPresent)
                    : netUseHelper.CreateMappedDrive(ComputerName, ComputerIpAddress, ShareName, Device, null, null, Force.IsPresent);

                WriteObject(result);

            }
        }
    }
}