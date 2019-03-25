using System;
using System.Management.Automation;
using Deployment.Installation;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsCommon.Get, "MsiKey")]
    [OutputType(typeof(MsiKey))]
    public class GetMsiKeyCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNullOrEmpty]
        public string Path { get; set; }

        protected override void ProcessRecord()
        {
            var installHelper = new InstallationHelper();

            var msiKey = installHelper.GetMsiKeyFromFile(Path);

            WriteObject(msiKey);
        }
    }
}