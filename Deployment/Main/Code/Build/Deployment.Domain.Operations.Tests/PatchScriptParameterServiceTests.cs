using System.IO;
using Deployment.Domain.Operations.Services;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class PatchScriptParameterServiceTests : DomainOperationsTestBase
    {
        const string DbFolder = "SimbleDb.DataMigrationScripts";

        [TestInitialize]
        public void TestInitialize()
        {
            //#var builder = new PackagePathBuilder(dropFolder, Logger);
        }

        [TestMethod]
        public void TestWritesPatchScriptParameterFile()
        {
            var dbScriptsFolder = Path.Combine(TestContext.TestDeploymentDir, DbFolder);

            if (!Directory.Exists(dbScriptsFolder))
                Directory.CreateDirectory(dbScriptsFolder);

            var files = new[] { "Test.AA.Parameters.xml", "Test.BB.Parameters.xml", "Test.Global.Parameters.xml" };

            CopyFiles(files, "Parameters");

            Config = "Test";
            OverrideConfig = null;

            var parameterService = new ParameterService(Logger);
            var packagePathBuilder =
                new PackagePathBuilder(TestContext.TestDeploymentDir, Logger) {IsLocalDebugMode = true};

            var patchScriptParameterService = new PatchScriptParameterService(parameterService, packagePathBuilder, Logger);
            var targetFile = Path.Combine(dbScriptsFolder, "ToRunParameters.sql");

            patchScriptParameterService.WritePatchScriptParameterFile(targetFile, Config, OverrideConfig);

            Assert.FileExists(targetFile, $"Target file {targetFile} was not found");

            //TODO: Read contents of file and ensure number of lines match
        }

        [TestMethod]
        public void TestWritesSqlCmdToRunFile()
        {
            var dbScriptsFolder = Path.Combine(TestContext.TestDeploymentDir, DbFolder);

            if (!Directory.Exists(dbScriptsFolder))
                Directory.CreateDirectory(dbScriptsFolder);

            var helperScriptsPath = Path.Combine(TestContext.TestDeploymentDir, @"HelperScripts\SQLHelpers\DeploymentHelpers");
            var parameterFilePath = Path.Combine(TestContext.TestDeploymentDir, "SimbleDb.DataMigrationScripts", "ToRunParameters.sql");

            //Not testing creation of ToRunParameters here, so use existing.
            var files = new[] { "Patching.sql", "ToRunParameters.sql" };

            CopyFiles(files, DbFolder);

            var sourcePath = Path.Combine(TestContext.TestDeploymentDir, "SimbleDb.DataMigrationScripts", "Patching.sql");
            var scriptItem = new FileInfo(sourcePath);

            var baseName = Path.GetFileNameWithoutExtension(sourcePath);
            var extension = scriptItem.Extension;

            var scriptRoot = scriptItem.Directory.Parent.FullName;
            var scriptParent = scriptItem.DirectoryName;

            var computerName = "localhost";

            var targetFile = Path.Combine(scriptParent,
                string.Concat(baseName, ".", computerName, extension, ".ToRun"));

            Config = "Test";
            OverrideConfig = null;

            var parameterService = new ParameterService(Logger);
            var packagePathBuilder =
                new PackagePathBuilder(TestContext.TestDeploymentDir, Logger) { IsLocalDebugMode = true };

            var patchScriptParameterService = new PatchScriptParameterService(parameterService, packagePathBuilder, Logger);

            patchScriptParameterService.WritePatchScriptRunFile(scriptRoot, targetFile, sourcePath, TestContext.TestDeploymentDir, "SimpleDb", computerName,
                helperScriptsPath, parameterFilePath, Config, "D");

            Assert.FileExists(targetFile, $"Target file {targetFile} was not found");
        }
    }
}