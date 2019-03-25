using System.Management.Automation;
using Deployment.Domain.Operations;
using Tfl.PowerShell.Common;

namespace TFL.Utilities.Commands
{
    [Cmdlet(VerbsSecurity.Protect, "AccountsFile")]
    public class ProtectAccountsFileCommand : PSCmdletBase
    {
        private string _path;

        [Parameter(Mandatory = true,
            Position = 0)]
        [ValidateNotNullOrEmpty]
        [Alias("ServiceAccountsFile", "AccountsFile")]
        public string Path
        {
            get { return _path; }
            set
            {
                _path = GetUnresolvedProviderPathFromPSPath(value);
            }
        }

        [Parameter(Mandatory = true)]
        [ValidateNotNull]
        [Alias("Password")]
        public string EncryptionPassword { get; set; }

        [Parameter]
        [Alias("OutputPath")]
        public string TargetPath { get; set; }

        protected override void ProcessRecord()
        {
            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);

            var manager = new ServiceAccountsManager(EncryptionPassword, logger);

            var success = manager.EncryptServiceAccountFile(_path, TargetPath);

            WriteObject(success);
        }
    }
}