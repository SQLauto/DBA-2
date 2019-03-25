using System.IO;
using Deployment.Domain.Operations.Services;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Deployment.Domain.Operations.Tests
{
    // These assume you've unpacked a set of DeploymentBasseline packages to D:\Deploy locally

    [TestClass]
    public class UpdateAppParametersFileCommandTests
    {
        private readonly string _cas1 = "10.107.236.30";

        private readonly string _cis1 = "10.107.236.28";
        // TESTING AGAINST RIG IS OK.
        // THIS READ THE ORIGINAL TRANSFORM FILE FROM _PublishedWebsites in Drop Folder and writes the updated file
        // It doesn't affect the resulting web config file

        private readonly string _db1 = "10.107.236.15";

        private readonly string _defaultConfig = "Baseline";

        private readonly string _dropFolder = @"\\10.107.236.15\D$\Deploy\DropFolder_Win\";
        private readonly string _environment = @"Baseline";
        private readonly string _rigName = @"DeploymentBaseline.RikDev";

        public TestContext TestContext { get; set; }

        [TestMethod]
        [TestCategory("112236_DynamicConfig")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateAppParametersFileCommand_SimpleConsoleAppX()
        {
            var targetPath = $@"\\{_cas1}\D$\TFL\Baseline\SimpleConsoleApp\";

            var targetFile = @"SimpleConsoleApp.exe.config";

            var overrideConfig = @"BaselineX";

            var packagePath = _dropFolder; // RETAINED_PAK_WORKING_DIR;

            Invoke_UpdateApplicationParametersFileCommand(_defaultConfig, overrideConfig, packagePath, _dropFolder,
                targetPath, targetFile, _environment, _rigName);
        }

        [TestMethod]
        [TestCategory("112236_DynamicConfig")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateAppParametersFileCommand_SimpleConsoleApp()
        {
            var overrideConfig = @"Baseline";

            var targetPath = $@"\\{_cis1}\D$\TFL\Baseline\SimpleConsoleApp\";

            var targetFile = @"SimpleConsoleApp.exe.config";

            var packagePath = _dropFolder; // RETAINED_PAK_WORKING_DIR;

            Invoke_UpdateApplicationParametersFileCommand(_defaultConfig, overrideConfig, packagePath, _dropFolder,
                targetPath, targetFile, _environment, _rigName);
        }

        [TestMethod]
        [TestCategory("112236_DynamicConfig")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateAppParametersFileCommand_SimpleConsoleAppMultiConfig()
        {
            var overrideConfig = @"BaselineX";

            var targetPath = $@"\\{_db1}\D$\TFL\Baseline\SimpleConsoleAppMultiConfig";

            var targetFile = "SimpleConsoleAppMultiConfig.exe.config";

            var packagePath = _dropFolder; //  RETAINED_PAK_WORKING_DIR;

            Invoke_UpdateApplicationParametersFileCommand(_defaultConfig, overrideConfig, packagePath, _dropFolder,
                targetPath, targetFile, _environment, _rigName);
        }

        [TestMethod]
        [TestCategory("112236_DynamicConfig")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateAppParametersFileCommand_SimpleWindowsService()
        {
            var overrideConfig = @"BaselineX";

            var targetFile = "SimpleWindowsService.exe.config";

            var targetPath = $@"\\{_cas1}\D$\TFL\Baseline\SimpleWindowsService";

            var packagePath = _dropFolder; // RETAINED_PAK_WORKING_DIR;

            Invoke_UpdateApplicationParametersFileCommand(_defaultConfig, overrideConfig, packagePath, _dropFolder,
                targetPath, targetFile, _environment, _rigName);
        }

        private void Invoke_UpdateApplicationParametersFileCommand(string defaultConfig, string overrideConfig,
            string packagePath, string dropFolder,
            string targetPath, string targetFile, string environment, string rigName)
        {
            var logger = new TestContextLogger(TestContext);
            logger?.WriteHeader("Update-ApplicationParametersFile");

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

            logger?.WriteLine(parameters.ToString());

            logger?.WriteLine($"Parsing PlaceholderMappings for Environment {environment}");
            var mappings = parameterService.GetPlaceholderMappings(builder, environment);

            logger?.WriteLine($"Parsing RigManifest for Rig {rigName}");
            var rigManifest = rigManifestService.GetRigManifest(builder);

            logger?.WriteLine("Transforming Application config file: " + targetFile);
            var retVal = configurationService.TransformApplicationConfiguration(overrideConfig, targetPath, packagePath,
                targetFile,
                parameters.Dictionary, mappings, rigManifest);

            var originalFile = Path.Combine(targetPath, targetFile + ".original");

            if (File.Exists(originalFile))
            {
                logger?.WriteLine("Deleting .orginal config file.");
                File.Delete(originalFile);
            }

            logger?.WriteLine("Successfully transformed application config file.");


            Assert.IsTrue(retVal, "Click 'Output' link for details.");
        }
    }
}