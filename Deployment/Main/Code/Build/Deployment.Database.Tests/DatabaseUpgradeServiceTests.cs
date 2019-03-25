using System.IO;
using Deployment.Common.Tests;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Deployment.Database.Tests
{
    [TestClass]
    public class DatabaseUpgradeServiceTests
    {
        public TestContext TestContext { get; set; }

        [ClassInitialize]
        public static void DeploymentFileXmlReader_ClassInitialise(TestContext context)
        {
            PrepareFiles(context, Path.Combine("1.2.3.4", "Partitioning.Database", "Scripts", "Patching", @"B000_R0000_AnyBaseline"));
            PrepareFiles(context, Path.Combine("1.2.3.4", "Partitioning.Database", "Scripts", "Patching", @"B001_R0001_DeployArtefacts"));
            PrepareFiles(context, Path.Combine("Partitioning.Database", "Scripts", "Patching", @"B000_R0000_AnyBaseline"));
            PrepareFiles(context, Path.Combine("Partitioning.Database", "Scripts", "Patching", @"B001_R0001_DeployArtefacts"));
        }

        private static void PrepareFiles(TestContext context, string path)
        {
            Directory.CreateDirectory(path);

            File.Copy(Path.Combine(context.TestDeploymentDir, "Patching.sql"),
                Path.Combine(path, "Patching.sql"),
                true);

            File.Copy(Path.Combine(context.TestDeploymentDir, "PreValidation.sql"),
                Path.Combine(path, "PreValidation.sql"),
                true);

            File.Copy(Path.Combine(context.TestDeploymentDir, "PostValidation.sql"),
                Path.Combine(path, "PostValidation.sql"),
                true);

            File.Copy(Path.Combine(context.TestDeploymentDir, "DetermineIfDatabaseIsAtThisPatchLevel.sql"),
                Path.Combine(path, "DetermineIfDatabaseIsAtThisPatchLevel.sql"),
                true);
        }

        [TestMethod]
        //[TestCategory("Gated")]
        [TestCategory("Database")]
        [TestCategory("Unit")]
        public void TestGeneratesPatchUpgradeDataAbsolute()
        {
            var parameters = new PatchUpgradeParameters
            {
                RootPath = TestContext.TestDeploymentDir,
                PatchFolderPath = Path.Combine(TestContext.TestDeploymentDir, @"Partitioning.Database\Scripts\Patching"),
                PatchFolderFormatStartsWith = "B???_R????_",
                UpgradeScriptName = "Patching.sql",
                PreValidationScriptName = "PreValidation.sql",
                PostValidationScriptName = "PostValidation.sql",
                DatabaseIsAtPatchLevelScriptName = "DetermineIfDatabaseIsAtThisPatchLevel.sql"
            };


            var logger = new TestContextLogger(TestContext);
            var upgradeService = new DatabaseUpgradeService(logger);

            var data = upgradeService.GetPatchesToUpgrade(parameters);

            Assert.IsTrue(data.IsValid);
            Assert.AreEqual(2, data.PatchUpgrades.Count);
            var patchUpgrade = data.PatchUpgrades[0];

            Assert.IsTrue(File.Exists(patchUpgrade.UpgradeScriptPath));
        }

        [TestMethod]
        //[TestCategory("Gated")]
        [TestCategory("Database")]
        [TestCategory("Unit")]
        public void TestGeneratesPatchUpgradeDataRelative()
        {
            var parameters = new PatchUpgradeParameters
            {
                RootPath = TestContext.TestDeploymentDir,
                PatchFolderPath = @"Partitioning.Database\Scripts\Patching",
                PatchFolderFormatStartsWith = "B???_R????_",
                UpgradeScriptName = "Patching.sql",
                PreValidationScriptName = "PreValidation.sql",
                PostValidationScriptName = "PostValidation.sql",
                DatabaseIsAtPatchLevelScriptName = "DetermineIfDatabaseIsAtThisPatchLevel.sql"
            };

            var logger = new TestContextLogger(TestContext);
            var upgradeService = new DatabaseUpgradeService(logger);

            var data = upgradeService.GetPatchesToUpgrade(parameters);

            Assert.IsTrue(data.IsValid);
            Assert.AreEqual(2, data.PatchUpgrades.Count);
            var patchUpgrade = data.PatchUpgrades[0];

            Assert.IsTrue(File.Exists(patchUpgrade.UpgradeScriptPath));
        }

        [TestMethod]
        //[TestCategory("Gated")]
        [TestCategory("Database")]
        [TestCategory("Unit")]
        public void TestGeneratesPatchUpgradeDataVersioned()
        {
            var parameters = new PatchUpgradeParameters
            {
                RootPath = Path.Combine(TestContext.TestDeploymentDir, "1.2.3.4"),
                PatchFolderPath = @"Partitioning.Database\Scripts\Patching",
                PatchFolderFormatStartsWith = "B???_R????_",
                UpgradeScriptName = "Patching.sql",
                PreValidationScriptName = "PreValidation.sql",
                PostValidationScriptName = "PostValidation.sql",
                DatabaseIsAtPatchLevelScriptName = "DetermineIfDatabaseIsAtThisPatchLevel.sql"
            };

            var logger = new TestContextLogger(TestContext);
            var upgradeService = new DatabaseUpgradeService(logger);

            var data = upgradeService.GetPatchesToUpgrade(parameters);

            Assert.IsTrue(data.IsValid);
            Assert.AreEqual(2, data.PatchUpgrades.Count);
            var patchUpgrade = data.PatchUpgrades[0];

            Assert.IsTrue(File.Exists(patchUpgrade.UpgradeScriptPath));
        }
    }
}
