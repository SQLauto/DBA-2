using Microsoft.VisualStudio.TestTools.UnitTesting;

using Deployment.Domain.Operations.Services;
using System.Collections.Generic;
using System.IO;
using Deployment.Common.Logging;
using Deployment.Domain.Parameters;

namespace Tfl.Deployment.Module.Tests
{
    // These assume you've unpacked a set of DeploymentBasseline packages to D:\Deploy locally

    [TestClass]
    public class UpdateWebParametersFilesCommandTests
    {
        private static readonly string DB1 = "10.107.236.30";
        //private string readonly string CAS1 = "10.107.236.27";
        //private string readonly string CIS1 = "10.107.236.31";

        private static readonly string DefaultConfig = "Baseline";
        private static readonly string Environment = "Baseline";
        private static readonly string RigName = "DeploymentBaseline.RikDev";
        private static readonly string RigConfigFile = "";

        private static string DropFolder = "";

        [ClassInitialize]
        public static void UpdateWebParametersFilesCommandTests_ClassInitialise(TestContext context)
        {
            DropFolder = $@"\\{DB1}\D$\Deploy\DropFolder_Web";
        }

        [TestMethod]
        [TestCategory("_DynamicConfigDEV")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateWebParametersFileCommand_SimpleMvcApp_Package()
        {
            string OverrideConfig = @"Baseline";

            string PackagePath = Path.Combine(DropFolder, @"_PublishedWebsites\SimpleMvcApp_Package");

            string PackageName = @"SimpleMvcApp";

            string SiteName = @"Simple Mvc App";
            
            Invoke_UpdateWebParametersFileCommand(DefaultConfig, OverrideConfig, Environment, RigName, PackagePath, DropFolder, PackageName, SiteName);
        }

        [TestMethod]
        [TestCategory("_DynamicConfigDEV")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateWebParametersFileCommand_SimpleWebSite_Package()
        {
            string OverrideConfig = @"";

            string PackagePath = Path.Combine(DropFolder, @"_PublishedWebsites\SimpleWebSite_Package");

            string PackageName = @"SimpleWebSite";

            string SiteName = @"Simple Web Site";

            Invoke_UpdateWebParametersFileCommand(DefaultConfig, OverrideConfig, Environment, RigName, PackagePath, DropFolder, PackageName, SiteName);
        }
        [TestMethod]
        [TestCategory("_DynamicConfigDEV")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateWebParametersFileCommand_SimpleWebSiteX_Package()
        {
            string OverrideConfig = @"BaselineX";

            string PackagePath = Path.Combine(DropFolder, @"_PublishedWebsites\SimpleWebSite_Package");

            string PackageName = @"SimpleWebSite";

            string SiteName = @"Simple Web SiteX";
            
            Invoke_UpdateWebParametersFileCommand(DefaultConfig, OverrideConfig, Environment, RigName, PackagePath, DropFolder, PackageName, SiteName);
        }

        [TestMethod]
        [TestCategory("_DynamicConfigDEV")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateWebParametersFileCommand_SimpleWebSiteXNS_Package()
        {
            string OverrideConfig = @"BaselineXNS";

            string PackagePath = Path.Combine(DropFolder, @"_PublishedWebsites\SimpleWebSite_Package");

            string PackageName = @"SimpleWebSite";

            string SiteName = @"Simple Web SiteXNS";
            
            Invoke_UpdateWebParametersFileCommand(DefaultConfig, OverrideConfig, Environment, RigName, PackagePath, DropFolder, PackageName, SiteName);
        }

        private void Invoke_UpdateWebParametersFileCommand(string DefaultConfig, string OverrideConfig, string Environment, string RigName,
                string PackagePath, string DropFolder, string PackageName, string SiteName)
        {
            // Prep of arguments for TransformWebParametersFile
            //var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);
            //var logger = new TextFileLogger(@"D:\Deploy\Logs", "TestUpdateWebParametersFileCommand.Log");
            var logger = new ConsoleLogger();
            logger?.WriteHeader("Preview Deployment");

            //So start by getting Deployment Paramers
            var parameterService = new ParameterService(logger);
            var configurationService = new ConfigurationTransformationService(parameterService, logger);
            var rigManifestService = new RigManifestService(logger);

            logger?.WriteLine($"Initialising PackagePathBuilder with build location of '{DropFolder}'");
            var builder = new PackagePathBuilder(DropFolder, logger);

            logger?.WriteLine($"Parsing PlaceholderMappings for config '{DefaultConfig}'");
            var mappings = parameterService.GetPlaceholderMappings(builder, DefaultConfig);

            logger?.WriteLine($"Parsing RigManifest for Rig {RigName}");
            RigManifest rigManifest = rigManifestService.GetRigManifest(builder);

            logger?.WriteLine($"Parsing DeploymentParameters with default config {DefaultConfig} and OverrideConfig {OverrideConfig} and Rig Specific Config {RigName}");
            var parameters = parameterService.ParseDeploymentParameters(builder, DefaultConfig, OverrideConfig, RigConfigFile, mappings, rigManifest);

            var setParametersFile = Path.Combine(PackagePath, PackageName + ".SetParameters.xml");
            logger?.WriteLine($"Updating SetParameters file {setParametersFile}");

            var corrections = new Dictionary<string, string> { { "IIS Web Application Name", SiteName } };
            bool retVal = configurationService.TransformWebParametersFile(setParametersFile, OverrideConfig, parameters.Dictionary, corrections, mappings, rigManifest);

            Assert.IsTrue(retVal, "Click 'Output' link for details.");
        }

    }
}