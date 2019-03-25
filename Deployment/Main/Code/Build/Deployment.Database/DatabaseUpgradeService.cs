using System;
using System.IO;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;

namespace Deployment.Database
{
    public class DatabaseUpgradeService : IDatabaseUpgradeService
    {
        private readonly IDeploymentLogger _logger;
        private readonly IFileHelper _fileHelper;

        public DatabaseUpgradeService(IDeploymentLogger logger = null, IFileHelper fileHelper = null)
        {
            _logger = logger;
            _fileHelper = fileHelper ?? new FileHelper();
        }

        public PatchUpgradeData IsPatchDefinitionValid(PatchUpgradeParameters upgradeParameters)
        {
            var patchUpgradeData = new PatchUpgradeData();
            var valid = ValidateParameter(patchUpgradeData, upgradeParameters.RootPath, "RootPath");

            if (!valid)
                return patchUpgradeData;

            if (!Directory.Exists(upgradeParameters.RootPath))
            {
                _logger?.WriteWarn($"Root Path '{upgradeParameters.RootPath}' does not exist");
                patchUpgradeData.ValidationErrors.Add($"Root Path '{upgradeParameters.RootPath}' does not exist");
                return patchUpgradeData;
            }

            valid = ValidateParameter(patchUpgradeData, upgradeParameters.PatchFolderPath, "PatchFolderPath");

            if (!valid)
                return patchUpgradeData;

            var patchFolderPath = Path.IsPathRooted(upgradeParameters.PatchFolderPath)
                ? upgradeParameters.PatchFolderPath
                : Path.Combine(upgradeParameters.RootPath, upgradeParameters.PatchFolderPath);

            if (!Directory.Exists(patchFolderPath))
            {
                _logger?.WriteWarn($"Patch folder path '{patchFolderPath}' does not exist");
                patchUpgradeData.ValidationErrors.Add($"Patch folder path '{patchFolderPath}' does not exist");
                return patchUpgradeData;
            }

            ValidateParameter(patchUpgradeData, upgradeParameters.PatchFolderFormatStartsWith, "PatchFolderFormatStartsWith");
            ValidateParameter(patchUpgradeData, upgradeParameters.PreValidationScriptName, "PreValidationScriptName");
            ValidateParameter(patchUpgradeData, upgradeParameters.UpgradeScriptName, "UpgradeScriptName");
            ValidateParameter(patchUpgradeData, upgradeParameters.DatabaseIsAtPatchLevelScriptName, "DatabaseIsAtPatchLevelScriptName");
            ValidateParameter(patchUpgradeData, upgradeParameters.PostValidationScriptName, "PostValidationScriptName");

            return patchUpgradeData;
        }

        public PatchUpgradeData GetPatchesToUpgrade(PatchUpgradeParameters upgradeParameters)
        {
            var patchUpgradeData = IsPatchDefinitionValid(upgradeParameters);

            if (!patchUpgradeData.IsValid)
                return patchUpgradeData;

            var patchFolderPath = Path.IsPathRooted(upgradeParameters.PatchFolderPath)
                ? upgradeParameters.PatchFolderPath
                : Path.Combine(upgradeParameters.RootPath, upgradeParameters.PatchFolderPath);

            _logger?.WriteLine($"Patch folder path set to {patchFolderPath}");

            var patchFolderSearch = upgradeParameters.PatchFolderFormatStartsWith + "*";
            var childDirectories = Directory.GetDirectories(patchFolderPath, patchFolderSearch, SearchOption.TopDirectoryOnly);

            if (childDirectories.Length > 0)
            {
                Array.Sort(childDirectories);
                Array.Reverse(childDirectories);
            }

            var ordinal = 0;

            foreach (var childDirectory in childDirectories)
            {
                var relativePath = _fileHelper.GetRelativePath(patchFolderPath, childDirectory);

                var upgradeScriptInfo = new PatchUpgradeScriptInfo
                {
                    RootPath = patchFolderPath,
                    FolderPath = relativePath,
                    PatchOrdinal = ordinal,
                    IsValid = true
                };

                upgradeScriptInfo.UpgradeScriptPath = Path.Combine(patchFolderPath, relativePath, upgradeParameters.UpgradeScriptName);
                if (!File.Exists(upgradeScriptInfo.UpgradeScriptPath))
                {
                    upgradeScriptInfo.ValidationErrors.Add(
                        $"UpgradeScript path does not exist: [{upgradeScriptInfo.UpgradeScriptPath}]");
                }

                upgradeScriptInfo.PreValidationScriptPath = Path.Combine(patchFolderPath, relativePath, upgradeParameters.PreValidationScriptName);
                if (!File.Exists(upgradeScriptInfo.PreValidationScriptPath))
                {
                    upgradeScriptInfo.ValidationErrors.Add(
                        $"PreValidationScript path does not exist: [{upgradeScriptInfo.PreValidationScriptPath}]");
                }

                upgradeScriptInfo.PostValidationScriptPath = Path.Combine(patchFolderPath, relativePath, upgradeParameters.PostValidationScriptName);
                if (!File.Exists(upgradeScriptInfo.PostValidationScriptPath))
                {
                    upgradeScriptInfo.ValidationErrors.Add(
                        $"PostValidationScript path does not exist: [{upgradeScriptInfo.PostValidationScriptPath}]");
                }

                upgradeScriptInfo.DatabaseIsAtPatchLevelScriptPath = Path.Combine(patchFolderPath, relativePath, upgradeParameters.DatabaseIsAtPatchLevelScriptName);
                if (!File.Exists(upgradeScriptInfo.DatabaseIsAtPatchLevelScriptPath))
                {
                    upgradeScriptInfo.ValidationErrors.Add(
                        $"DetermineIfDatabaseIsAtThisPatchLevelScript path does not exist: [{upgradeScriptInfo.DatabaseIsAtPatchLevelScriptPath}]");
                }

                patchUpgradeData.PatchUpgrades.Add(upgradeScriptInfo);
                ordinal++;
            }

            return patchUpgradeData;
        }

        private static bool ValidateParameter(PatchUpgradeData patchUpgradeData, string path, string name)
        {
            if (!string.IsNullOrWhiteSpace(path))
                return true;

            patchUpgradeData.ValidationErrors.Add($"{name} is null or empty");
            return false;
        }
    }
}