namespace Deployment.Database
{
    public class PatchUpgradeParameters
    {
        public string RootPath { get; set; }
        public string PatchFolderPath { get; set; }
        public string PatchFolderFormatStartsWith { get; set; }
        public string UpgradeScriptName { get; set; }
        public string PreValidationScriptName { get; set; }
        public string PostValidationScriptName { get; set; }
        public string DatabaseIsAtPatchLevelScriptName { get; set; }
    }
}