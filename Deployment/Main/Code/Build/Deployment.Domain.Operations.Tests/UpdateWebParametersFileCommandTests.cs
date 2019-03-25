using System.Collections.Generic;
using System.IO;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Operations.Tests;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Tfl.Deployment.Module.Tests
{
    // These assume you've unpacked a set of DeploymentBasseline packages to D:\Deploy locally

    [TestClass]
    public class UpdateWebParametersFilesCommandTests
    {
        private string _cas1 = "10.107.236.30";
        private string _cis1 = "10.107.236.28";
        private string _db1 = "10.107.236.15";

        private readonly string _defaultConfig = "Baseline";

        private readonly string _dropFolder = @"\\10.107.236.15\D$\Deploy\DropFolder_Web";
        private readonly string _environment = "Baseline";
        private readonly string _rigName = "DeploymentBaseline.RikDev";

        public TestContext TestContext { get; set; }

        [TestMethod]
        [TestCategory("112236_DynamicConfig")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateWebParametersFileCommand_SimpleMvcApp_Package()
        {
            var overrideConfig = @"Baseline";

            var packagePath = Path.Combine(_dropFolder, @"_PublishedWebsites\SimpleMvcApp_Package");

            var packageName = @"SimpleMvcApp";

            var siteName = @"Simple Mvc App";

            Invoke_UpdateWebParametersFileCommand(_defaultConfig, overrideConfig, _environment, _rigName, packagePath,
                _dropFolder, packageName, siteName);
        }

        [TestMethod]
        [TestCategory("112236_DynamicConfig")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateWebParametersFileCommand_SimpleWebSite_Package()
        {
            var overrideConfig = @"";

            var packagePath = Path.Combine(_dropFolder, @"_PublishedWebsites\SimpleWebSite_Package");

            var packageName = @"SimpleWebSite";

            var siteName = @"Simple Web Site";

            Invoke_UpdateWebParametersFileCommand(_defaultConfig, overrideConfig, _environment, _rigName, packagePath,
                _dropFolder, packageName, siteName);
        }

        [TestMethod]
        [TestCategory("112236_DynamicConfig")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateWebParametersFileCommand_SimpleWebSiteX_Package()
        {
            var overrideConfig = @"BaselineX";

            var packagePath = Path.Combine(_dropFolder, @"_PublishedWebsites\SimpleWebSite_Package");

            var packageName = @"SimpleWebSite";

            var siteName = @"Simple Web SiteX";

            Invoke_UpdateWebParametersFileCommand(_defaultConfig, overrideConfig, _environment, _rigName, packagePath,
                _dropFolder, packageName, siteName);
        }

        [TestMethod]
        [TestCategory("112236_DynamicConfig")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateWebParametersFileCommand_SimpleWebSiteXNS_Package()
        {
            var overrideConfig = @"BaselineXNS";

            var packagePath = Path.Combine(_dropFolder, @"_PublishedWebsites\SimpleWebSite_Package");

            var packageName = @"SimpleWebSite";

            var siteName = @"Simple Web SiteXNS";

            Invoke_UpdateWebParametersFileCommand(_defaultConfig, overrideConfig, _environment, _rigName, packagePath,
                _dropFolder, packageName, siteName);
        }

        private void Invoke_UpdateWebParametersFileCommand(string defaultConfig, string overrideConfig,
            string environment, string rigName,
            string packagePath, string dropFolder, string packageName, string siteName)
        {
            // Prep of arguments for TransformWebParametersFile
            //var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);
            //var logger = new TextFileLogger(@"D:\Deploy\Logs", "TestUpdateWebParametersFileCommand.Log");
            var logger = new TestContextLogger(TestContext);
            logger?.WriteHeader("Preview Deployment");

            //So start by getting Deployment Paramers
            var parameterService = new ParameterService(logger);
            var configurationService = new ConfigurationTransformationService(parameterService, logger);
            var rigManifestService = new RigManifestService(logger);

            logger?.WriteLine($"Initialising PackagePathBuilder with build location of '{dropFolder}'");
            var builder = new PackagePathBuilder(dropFolder, logger);

            logger?.WriteLine(
                $"Parsing DeploymentParameters with default config {defaultConfig} and OverrideConfig {overrideConfig} and Rig Specific Config {rigName}");
            var parameters =
                parameterService.ParseDeploymentParameters(builder, defaultConfig, overrideConfig, rigName);

            logger?.WriteLine($"Parsing PlaceholderMappings for Environment {environment}");
            var mappings = parameterService.GetPlaceholderMappings(builder, environment);

            logger?.WriteLine($"Parsing RigManifest for Rig {rigName}");
            var rigManifest = rigManifestService.GetRigManifest(builder);

            var setParametersFile = Path.Combine(packagePath, packageName + ".SetParameters.xml");
            logger?.WriteLine($"Updating SetParameters file {setParametersFile}");

            var corrections = new Dictionary<string, string> {{"IIS Web Application Name", siteName}};
            var retVal = configurationService.TransformWebParametersFile(setParametersFile, overrideConfig,
                parameters.Dictionary, corrections, mappings, rigManifest);

            Assert.IsTrue(retVal, "Click 'Output' link for details.");
        }
    }
}