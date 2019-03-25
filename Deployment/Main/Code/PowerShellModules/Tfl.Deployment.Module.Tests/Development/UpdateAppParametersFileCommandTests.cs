using Microsoft.VisualStudio.TestTools.UnitTesting;

using Deployment.Domain.Operations.Services;
using System.IO;
using Deployment.Common.Logging;

namespace Tfl.Deployment.Module.Tests
{
    // These assume you've unpacked a set of DeploymentBasseline packages to D:\Deploy locally

    [TestClass]
    public class UpdateAppParametersFileCommandTests
    {
        // TESTING AGAINST RIG IS OK.
        // This read from the _PublishedWebsites in Drop Folder and writes the updated file to the target install folder
        // It re-runs the deployment configuration piece

        private static readonly string DB1 = "10.107.236.30";
        private static readonly string CAS1 = "10.107.236.27";
        private static readonly string CIS1 = "10.107.236.31";

        private static readonly string DefaultConfig = "Baseline";
        private static readonly string Environment = @"Baseline";
        private static readonly string RigName = @"DeploymentBaseline.RikDev";
        private static readonly string RigConfigFile = "";

        private static string DropFolder = "";

        [ClassInitialize]
        public static void UpdateWebParametersFilesCommandTests_ClassInitialise(TestContext context)
        {
            DropFolder = $@"\\{DB1}\D$\Deploy\DropFolder_Win";
        }

        [TestMethod]
        [TestCategory("_DynamicConfigDEV")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateAppParametersFileCommand_SimpleConsoleAppX()
        {
            string TargetPath = $@"\\{CAS1}\D$\TFL\Baseline\SimpleConsoleApp\";

            string TargetFile = @"SimpleConsoleApp.exe.config";

            string OverrideConfig = @"BaselineX";

            string PackagePath = DropFolder;

            Invoke_UpdateApplicationParametersFileCommand(DefaultConfig, OverrideConfig, PackagePath, DropFolder, TargetPath, TargetFile, Environment, RigName);
        }

        [TestMethod]
        [TestCategory("_DynamicConfigDEV")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateAppParametersFileCommand_SimpleConsoleApp()
        {
            string OverrideConfig = @"Baseline";
            
            string TargetPath = $@"\\{CIS1}\D$\TFL\Baseline\SimpleConsoleApp\";

            string TargetFile = @"SimpleConsoleApp.exe.config";

            string PackagePath = DropFolder;

            Invoke_UpdateApplicationParametersFileCommand(DefaultConfig, OverrideConfig, PackagePath, DropFolder, TargetPath, TargetFile, Environment, RigName);
        }

        [TestMethod]
        [TestCategory("_DynamicConfigDEV")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateAppParametersFileCommand_SimpleConsoleAppMultiConfig()
        {
            string OverrideConfig = @"BaselineX";

            string TargetPath = $@"\\{DB1}\D$\TFL\Baseline\SimpleConsoleAppMultiConfig";

            string TargetFile = "SimpleConsoleAppMultiConfig.exe.config";

            string PackagePath = DropFolder; //  RETAINED_PAK_WORKING_DIR;

            Invoke_UpdateApplicationParametersFileCommand(DefaultConfig, OverrideConfig, PackagePath, DropFolder, TargetPath, TargetFile, Environment, RigName);
        }

        [TestMethod]
        [TestCategory("_DynamicConfigDEV")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVUpdateAppParametersFileCommand_SimpleWindowsService()
        {
            string OverrideConfig = @"BaselineX";

            string TargetFile = "SimpleWindowsService.exe.config";

            string TargetPath = $@"\\{CAS1}\D$\TFL\Baseline\SimpleWindowsService";

            string PackagePath = DropFolder; // RETAINED_PAK_WORKING_DIR;

            Invoke_UpdateApplicationParametersFileCommand(DefaultConfig, OverrideConfig, PackagePath, DropFolder, TargetPath, TargetFile, Environment, RigName);
        }

        private void Invoke_UpdateApplicationParametersFileCommand(string DefaultConfig, string OverrideConfig, string PackagePath, string DropFolder, 
                string TargetPath, string TargetFile, string Environment, string RigName)
        {
            // Prep of arguments for TransformWebParametersFile
            //var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);
            //var logger = new TextFileLogger(@"D:\Deploy\Logs", "TestUpdateWebParametersFileCommand.Log");
            var logger = new ConsoleLogger();
            logger?.WriteHeader("Update-ApplicationParametersFile");

            //So start by getting Deployment Paramers
            var parameterService = new ParameterService(logger);
            var configurationService = new ConfigurationTransformationService(parameterService, logger);
            var rigManifestService = new RigManifestService(logger);

            logger?.WriteLine($"Initialising PackagePathBuilder with build location of '{DropFolder}'");
            var builder = new PackagePathBuilder(DropFolder, logger);

            logger?.WriteLine($"Parsing PlaceholderMappings for config '{DefaultConfig}'");
            var mappings = parameterService.GetPlaceholderMappings(builder, DefaultConfig);

            logger?.WriteLine($"Parsing RigManifest for Rig '{RigName}'");
            var rigManifest = rigManifestService.GetRigManifest(builder);

            logger?.WriteLine($"Parsing DeploymentParameters with default config {DefaultConfig} and OverrideConfig {OverrideConfig} and Rig Specific Config {RigName}");
            var parameters = parameterService.ParseDeploymentParameters(builder, DefaultConfig, OverrideConfig, RigConfigFile, mappings, rigManifest);

            //logger?.WriteLine(parameters.ToString());

            logger?.WriteLine("Transforming Application config file: " + TargetFile);
            bool retVal = configurationService.TransformApplicationConfiguration(OverrideConfig, TargetPath, PackagePath, TargetFile, 
                                                                                 parameters.Dictionary, mappings, rigManifest);

            var originalFile = Path.Combine(TargetPath, TargetFile + ".original");

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