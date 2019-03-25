using System.Management.Automation;
using Deployment.Domain.Operations;
using Tfl.PowerShell.Common;

namespace TFL.Utilities.Commands
{
    [Cmdlet(VerbsSecurity.Unprotect, "AccountsFile")]
    public class UnprotectAccountsFileCommand : PSCmdletBase
    {
        private string _path;

        [Parameter(Mandatory = true,
            Position = 0)]
        [ValidateNotNullOrEmpty]
        [Alias("ServiceAccountsFile","AccountsFile")]
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
        public string DecryptionPassword { get; set; }

        [Parameter]
        [Alias("OutputPath")]
        public string TargetPath { get; set; }

        protected override void ProcessRecord()
        {
            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);

            logger.WriteLine($"Path set to: {_path}");

            var manager = new ServiceAccountsManager(DecryptionPassword, logger);

            var success = manager.DecryptServiceAccountFile(_path, TargetPath);

            WriteObject(success);
        }
    }
}