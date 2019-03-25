using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using Deployment.Common;
using Deployment.Common.Logging;
using Microsoft.Deployment.WindowsInstaller;

namespace Deployment.Installation
{
    public enum SearchMode
    {
        ByUpgragdeCode,
        ByProductCode
    }

    public sealed class InstallationHelper
    {
        private static readonly Mutex processWideLock = new Mutex(false, "Deployment.Installation.InstallationHelper.Mutex");
        private readonly IDeploymentLogger _logger;

        public InstallationHelper(IDeploymentLogger logger = null)
        {
            _logger = logger;
        }

        /// <summary>
        /// Tests to see if a installation exists.
        /// </summary>
        /// <param name="productOrUpgradeCode">Installers product or upgrade code - this should vary across installations, however old TFL installers kept this constant!</param>
        /// <param name="mode"></param>
        /// <returns>True if there is an installation with specified product code</returns>
        public bool GetProductExists(Guid productOrUpgradeCode, SearchMode mode = SearchMode.ByUpgragdeCode)
        {
            var exists = mode == SearchMode.ByUpgragdeCode ? GetProductsByUpgradeCode(productOrUpgradeCode).Count > 0 : GetProductsByProductCode(productOrUpgradeCode).Count > 0;
            return exists;
        }

        public PropertyCheck ExpectedPublicPropertiesExist(string msiFilePath, IList<string> propertiesOfInterest)
        {
            msiFilePath = Path.GetFullPath(msiFilePath);

            if (!File.Exists(msiFilePath))
            {
                throw new Exception(
                    $"On server [{Environment.MachineName}], Msifile path does not exist: [{msiFilePath ?? "parameter is null"}] ");
            }

            processWideLock.WaitOne();
            var check = new PropertyCheck();

            try
            {
                Installer.SetInternalUI(InstallUIOptions.Silent);

                using (var package = Installer.OpenPackage(msiFilePath, true))
                {
                    bool customActionsExist = false;
                    foreach (var tableInfo in package.Database.Tables)
                    {
                        if (tableInfo.Name == "CustomAction")
                        {
                            customActionsExist = tableInfo.PrimaryKeys != null && tableInfo.PrimaryKeys.Count > 0;
                            break;
                        }
                    }

                    foreach (var property in propertiesOfInterest)
                    {
                        var propertyExists = false;

                        var prop = property.ToUpperInvariant();

                        var propertyValue = package.Database.ExecutePropertyQuery(prop);
                        if (propertyValue != null) // this should be a null check empty string is valid
                        {
                            propertyExists = true;
                        }

                        if (customActionsExist)
                        {
                            var record = new Record("Action", "Type", "Source", "Target", "ExtendedType");

                            var query = package.Database.ExecuteQuery(
                                "SELECT `Action`, `Type`, `Source`, `Target`, `ExtendedType` FROM `CustomAction`",
                                record);

                            var enumerator = query.GetEnumerator();
                            while (enumerator.MoveNext())
                            {
                                object item = enumerator.Current;
                                // Perform logic on the item
                                if (item != null)
                                {
                                    if (item.ToString().Contains(prop))
                                    {
                                        propertyExists = true;
                                    }
                                }
                            }
                        }

                        if (propertyExists)
                            continue;

                        check.InvalidPropertyNames.Add(prop);
                        check.AllExpectedPropertiesExist = false;
                    }
                }
            }
            finally
            {
                processWideLock.ReleaseMutex();
            }

            return check;
        }

        public MsiKey GetMsiKeyFromFile(string msiFilePath)
        {
            var key = GetMsiKeyFromFile(msiFilePath, false);
            return key;
        }

        public bool ValidateMsiUpgradeCode(MsiKey key, Guid upgradeCode)
        {
            if (upgradeCode == Guid.Empty)
            {
                throw new Exception("Upgrade code must not be empty guid");
            }

            var expected = upgradeCode == key.UpgradeCode;
            return expected;
        }

        public bool ValidateMsiProductCode(MsiKey key, Guid productCode)
        {
            if (productCode == Guid.Empty)
            {
                throw new Exception("Product code must not be empty");
            }

            var expected = productCode == key.ProductCode;
            return expected;
        }

        public IList<Version> GetVersionsFromUpgradeCode(Guid upgradeCode)
        {
            if (upgradeCode == Guid.Empty)
            {
                throw new Exception("Upgrade code must not be empty");
            }

            var installations = GetProductsByUpgradeCode(upgradeCode);
            return installations.Count == 0 ? new Version[0] : installations.Select(installation => installation.ProductVersion).ToArray();
        }

        public string GetInstallLocationFromProductCode(Guid productCode)
        {
            if (productCode == Guid.Empty)
            {
                throw new Exception("Product code must not be empty");
            }

            var installations = GetProductsByProductCode(productCode);
            if (installations.Count == 0)
            {
                return string.Empty;
            }

            string installationLocation = installations[0].InstallLocation;

            return installationLocation;
        }

        public IList<MsiInfo> GetInstalledProducts(Guid productOrUpgradeCodeCode, SearchMode mode = SearchMode.ByUpgragdeCode)
        {
            if (productOrUpgradeCodeCode == Guid.Empty)
                throw new ArgumentException(mode == SearchMode.ByProductCode ? "ProductCode must not be empty" : "UpgradeCode must not be empty");

            var installations = mode == SearchMode.ByUpgragdeCode ? GetProductsByUpgradeCode(productOrUpgradeCodeCode) : GetProductsByProductCode(productOrUpgradeCodeCode);

            return installations.Select(pi => new MsiInfo(pi,mode == SearchMode.ByUpgragdeCode
                ? new MsiKey(productOrUpgradeCodeCode, ToGuid(pi.ProductCode), pi.ProductVersion)
                : GetMsiKeyFromFile(pi.LocalPackage, false, false))).ToList();
        }

        public bool IsDowngradeInstallationRequest(MsiKey key)
        {
            if (!key.HasVersion)
                return false;

            var installations = !key.HasUpgradeCode && key.HasProductCode
                ? GetProductsByProductCode(key.ProductCode)
                : GetProductsByUpgradeCode(key.UpgradeCode);

            return !installations.IsNullOrEmpty() && IsDowngradeInstallationRequest(installations, key.ProductVersion);
        }

        public MsiInfo GetInstalledProduct(MsiKey key)
        {
            if (!key.HasVersion)
            {
                _logger?.WriteWarn("Passed in MsiKey does not have a version info.");
                return MsiInfo.Empty;
            }

            var installations = !key.HasUpgradeCode && key.HasProductCode
                ? GetInstalledProducts(key.ProductCode, SearchMode.ByProductCode)
                : GetInstalledProducts(key.UpgradeCode);

            if (installations.IsNullOrEmpty())
            {
                _logger?.WriteLine($"No installed products were found for MsiKey {key}");
                return MsiInfo.Empty;
            }

            var downGrade = installations.FirstOrDefault(i => i.Key.ProductVersion > key.ProductVersion);

            if (downGrade != null)
            {
                _logger?.WriteWarn($"MsiKey {key} passed in specifies a downgrade.");
                downGrade.IsDowngrade = true;
                return downGrade;
            }

            var found = installations.FirstOrDefault(i => i.Key.Equals(key));

            if (found == null)
            {
                _logger?.WriteWarn($"No installed products were found for MsiKey {key}");
            }

            return found ?? MsiInfo.Empty;
        }

        public bool IsProductInstalled(Guid productOrUpgradeCodeCode, SearchMode mode = SearchMode.ByUpgragdeCode)
        {
            var installations = GetInstalledProducts(productOrUpgradeCodeCode, mode);

            return installations.Count > 0;
        }

        public IList<MsiInfo> GetAllInstalledProducts()
        {
            try
            {
                processWideLock.WaitOne();
                var installations = ProductInstallation.AllProducts;

                var msiInfos = installations.Select(pi => new MsiInfo(pi, GetMsiKeyFromFile(pi.LocalPackage, true, false))).ToList();

                return msiInfos;
            }
            finally
            {
                processWideLock.ReleaseMutex();
            }
        }

        private string ToRegistryFormatGuidString(Guid code)
        {
            return code.ToString("B");
        }

        private IList<ProductInstallation> GetProductsByUpgradeCode(Guid upgradeCode)
        {
            string code = ToRegistryFormatGuidString(upgradeCode);
            IEnumerable<ProductInstallation> installations;
            try
            {
                processWideLock.WaitOne();
                installations = ProductInstallation.GetRelatedProducts(code);
            }
            finally
            {
                processWideLock.ReleaseMutex();
            }

            return installations.ToList();
        }

        private IList<ProductInstallation> GetProductsByProductCode(Guid productCode)
        {
            string code = ToRegistryFormatGuidString(productCode);
            string userSidTheWorld = "s-1-1-0";
            IEnumerable<ProductInstallation> installations;
            try
            {
                processWideLock.WaitOne();
                installations = ProductInstallation.GetProducts(code, userSidTheWorld, UserContexts.All);
            }
            finally
            {
                processWideLock.ReleaseMutex();
            }

            return installations.ToList();
        }

        private bool IsDowngradeInstallationRequest(IList<ProductInstallation> installations, Version version)
        {
            return installations.Any(installation => installation.ProductVersion > version);
        }

        private MsiKey GetMsiKeyFromFile(string msiFilePath, bool lockAlreadyTaken, bool throwOnMissingFile = true)
        {
            msiFilePath = Path.GetFullPath(msiFilePath);

            if (!File.Exists(msiFilePath))
            {
                if (throwOnMissingFile)
                    throw new Exception(
                        $"On server [{Environment.MachineName}], Msifile path does not exist: [{msiFilePath}]");

                return null;
            }

            try
            {
                if (!lockAlreadyTaken)
                    processWideLock.WaitOne();

                Installer.SetInternalUI(InstallUIOptions.Silent);

                string productCode;
                string upgradeCode;
                string productVersion;

                using (var package = Installer.OpenPackage(msiFilePath, true))
                {
                    productCode = package.GetProductProperty("ProductCode");
                    upgradeCode = package.GetProductProperty("UpgradeCode");
                    productVersion = package.GetProductProperty("ProductVersion");
                }



                var productCodeGuid = ToGuid(productCode);

                if (productCodeGuid == Guid.Empty)
                {
                    throw new Exception(
                        $"On server [{Environment.MachineName}], unable to parse product code guid: [{productCode}] from installer: [{msiFilePath}] ");
                }

                var upgradeCodeGuid = ToGuid(upgradeCode);

                if (upgradeCodeGuid == Guid.Empty)
                {
                    throw new Exception(
                        $"On server [{Environment.MachineName}], unable to parse upgrade code guid: [{upgradeCode}] from installer: [{msiFilePath}] ");
                }

                Version version;
                var result = Version.TryParse(productVersion, out version);

                if (!result)
                {
                    throw new Exception(
                        $"On server [{Environment.MachineName}], unable to parse product version: [{productVersion}] from installer: [{msiFilePath}] ");
                }

                return new MsiKey(upgradeCodeGuid, productCodeGuid, version);
            }
            finally
            {
                if (!lockAlreadyTaken)
                    processWideLock.ReleaseMutex();
            }
        }

        private Guid ToGuid(string code)
        {
            Guid guid;
            var result = Guid.TryParse(code ?? string.Empty, out guid);

            return result ? guid : Guid.Empty;
        }
    }
}
