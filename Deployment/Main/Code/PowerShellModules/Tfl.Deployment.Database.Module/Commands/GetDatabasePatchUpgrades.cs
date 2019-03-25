using System.Management.Automation;
using Deployment.Database;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Database.Commands
{
    [Cmdlet(VerbsCommon.Get, "DatabasePatchUpgrades")]
    public class GetDatabasePatchUpgrades : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNullOrEmpty]
        public string Path { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string PatchFolderPath { get; set; }
        [Parameter]
        public string UpgradeScript { get; set; }
        [Parameter]
        public string PreValidationScript { get; set; }
        [Parameter]
        public string PostValidationScript { get; set; }
        [Parameter]
        public string PatchLevelDeterminationScript { get; set; }
        [Parameter]
        public string PatchFolderFormatStartsWith { get; set; }

        protected override void ProcessRecord()
        {
            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);

            var parameters = new PatchUpgradeParameters
            {
                RootPath = Path,
                PatchFolderPath = PatchFolderPath,
                PatchFolderFormatStartsWith = PatchFolderFormatStartsWith,
                UpgradeScriptName = UpgradeScript,
                PreValidationScriptName = PreValidationScript,
                PostValidationScriptName = PostValidationScript,
                DatabaseIsAtPatchLevelScriptName = PatchLevelDeterminationScript
            };

            var validationService = new DatabaseUpgradeService(logger);

            var results = validationService.GetPatchesToUpgrade(parameters);

            WriteObject(results);
        }
    }
}