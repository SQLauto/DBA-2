using System.Collections.Generic;

namespace Deployment.Database
{
    public class PatchUpgradeScriptInfo
    {
        public PatchUpgradeScriptInfo()
        {
            ValidationErrors = new List<string>();
        }

        public bool IsValid { get; set; }
        public int PatchOrdinal { get; set; }
        public string RootPath { get; set; }
        public string FolderPath { get; set; }
        public string UpgradeScriptPath { get; set; }
        public string PreValidationScriptPath { get; set; }
        public string PostValidationScriptPath { get; set; }
        public string DatabaseIsAtPatchLevelScriptPath { get; set; }
        public IList<string> ValidationErrors { get; }
    }
}