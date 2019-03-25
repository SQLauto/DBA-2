using System.Management.Automation;
using Deployment.Common.Helpers;
using Tfl.PowerShell.Common;

namespace TFL.Utilities.Commands
{
    [Cmdlet(VerbsCommon.Remove, "MappedDrive")]
    public class RemoveMappedDriveCommand : PSCmdletBase
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
        public string DeviceName { get; set; }

        protected override void ProcessRecord()
        {
            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);

            using (var netUseHelper = new NetUseHelper(logger))
            {
                var result = netUseHelper.DeleteMappedDrive(ComputerName, ComputerIpAddress, ShareName);

                WriteObject(result);
            }
        }
    }
}