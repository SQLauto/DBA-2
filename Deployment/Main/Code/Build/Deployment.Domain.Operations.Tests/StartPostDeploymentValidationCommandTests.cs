using System;
using System.Collections.Generic;
using Deployment.Common;
using Deployment.Common.Logging;
using Deployment.Domain.Operations.Services;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class StartPostDeploymentValidationCommandTests
    {
        private const string RetainedReleaseWorkingDir = @"\\TDC2BLD015\D$\B\03\_work\1696b82e3\DeploymentBaseline.RikDev.PAK";

        public TestContext TestContext { get; set; }

        [TestMethod]
        [TestCategory("112236_DynamicConfig")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVStartPostDeploymentValidationCommand_Apps()
        {
            string configuration = "Baseline.Apps.config.xml";
            string serviceAccountsPassword = "Olymp1c$2012";

            string buildLocation = $@"{RetainedReleaseWorkingDir}\Deployment"; //  $@"{RETAINED_RELEASE_WORKING_DIR}\Deployment";
            string rigName = "DeploymentBaseline.RikDev";
            string driveLetter = "D";
            string logPath = $@"{RetainedReleaseWorkingDir}\devlogs\";
            string environmentType = "VCloud";

            //bool LocalDebug = true;
            //IList<string> Groups = new List<string>();
            //IList<string> Servers = new List<string>();
            //string Partition = "";
            //bool RemoveMappings = false;

            Invoke_StartPostDeploymentValidationCommand(logPath, driveLetter, buildLocation, configuration, rigName, environmentType, serviceAccountsPassword);
        }

        [TestMethod]
        [TestCategory("112236_DynamicConfig")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVStartPostDeploymentValidationCommand_DB()
        {
            string configuration = "Baseline.DB.config.xml";
            string serviceAccountsPassword = "Olymp1c$2012";

            string buildLocation = $@"{RetainedReleaseWorkingDir}\Deployment";
            string rigName = "DeploymentBaseline.RikDev";
            string driveLetter = "D";
            string logPath = $@"{RetainedReleaseWorkingDir}\devlogs\";
            string environmentType = "VCloud";

            //bool LocalDebug = true;
            //IList<string> Groups = new List<string>();
            //IList<string> Servers = new List<string>();
            //string Partition = "";
            //bool RemoveMappings = false;

            Invoke_StartPostDeploymentValidationCommand(logPath, driveLetter, buildLocation, configuration, rigName, environmentType, serviceAccountsPassword);
        }

        private void Invoke_StartPostDeploymentValidationCommand(string logPath, string driveLetter, string buildLocation, string configuration, string rigName,
                string environmentType, string serviceAccountsPassword,
                bool localDebug = true, IList<string> groups = null, IList<string> servers = null)
        {
            bool? result = null;
            try
            {
                if (string.IsNullOrEmpty(logPath))
                {
                    logPath = $@"{driveLetter}:\Deploy\Logs";
                }

                var logger = new TestContextLogger(TestContext);

                var parameterService = new ParameterService(logger);

                var builder = string.IsNullOrWhiteSpace(buildLocation) ? new RootPathBuilder(@"D:\Deploy\DropFolder") : new RootPathBuilder(buildLocation)
                {
                    IsLocalDebugMode = localDebug,
                    OutputDirectory = logPath
                };

                var parameters = new DeploymentOperationParameters
                {
                    Groups = groups ?? new List<string>(),
                    Servers = servers ?? new List<string>(),
                    DecryptionPassword = serviceAccountsPassword,
                    DeploymentConfigFileName = configuration,
                    DriveLetter = driveLetter,
                    Username = @"FAELAB\tfsbuild", // Credential.UserName,
                    Password = serviceAccountsPassword // Credential.GetNetworkCredential().Password
                };

                switch (environmentType)
                {
                    case "VCloud":
                        parameters.Platform = DeploymentPlatform.VCloud;
                        parameters.RigName = rigName;
                        break;
                    case "Azure":
                        parameters.Platform = DeploymentPlatform.Azure;
                        parameters.RigName = rigName;
                        break;
                    default:
                        parameters.Platform = DeploymentPlatform.CurrentDomain;
                        break;
                }

                var validator = new DeploymentValidation(parameterService, logger);
                result = validator.PostDeploymentValidation(builder, parameters);
            }
            catch (Exception ex)
            {
                Assert.Fail("An exception ocurred in Invoke_StartPostDeploymentValidationCommand: " + ex.Message);
            }

            if (result.HasValue)
            {
                Assert.IsTrue(result.Value, "Click 'Output' link for details.");
            }
            else
            {
                Assert.Fail("result variable not set by end of test.");
            }
            //WriteObject(result);
        }


    }
}