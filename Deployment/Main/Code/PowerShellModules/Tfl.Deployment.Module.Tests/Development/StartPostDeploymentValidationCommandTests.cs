using Microsoft.VisualStudio.TestTools.UnitTesting;

using Deployment.Domain.Operations.Services;
using System.Collections.Generic;
using System.IO;
using Deployment.Common.Logging;
using Deployment.Common;
using Deployment.Domain.Operations;
using System;

namespace Tfl.Deployment.Module.Tests
{
    [TestClass]
    public class StartPostDeploymentValidationCommandTests
    {
        private string RETAINED_RELEASE_WORKING_DIR = @"\\TDC2BLD015\D$\B\02\_work\r6\a\DeploymentBaseline.RikDev.PAK";

        [TestMethod]
        [TestCategory("_PDVT_DEV")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVStartPostDeploymentValidationCommand_Apps()
        {
            string Configuration = "Baseline.Apps.config.xml";
            string ServiceAccountsPassword = "Olymp1c$2012";

            string BuildLocation = $@"{RETAINED_RELEASE_WORKING_DIR}\Deployment"; //  $@"{RETAINED_RELEASE_WORKING_DIR}\Deployment";
            string RigName = "DeploymentBaseline.RikDev";
            string DriveLetter = "D";
            string LogPath = $@"{RETAINED_RELEASE_WORKING_DIR}\devlogs\";
            string EnvironmentType = "VCloud";

            //bool LocalDebug = true;
            //IList<string> Groups = new List<string>();
            //IList<string> Servers = new List<string>();
            //string Partition = "";
            //bool RemoveMappings = false;            

            Invoke_StartPostDeploymentValidationCommand(LogPath, DriveLetter, BuildLocation, Configuration, RigName, EnvironmentType, ServiceAccountsPassword);
        }

        [TestMethod]
        [TestCategory("_PDVT_DEV")]
        //[TestCategory("Unit")]
        //[TestCategory("Gated")]
        public void DEVStartPostDeploymentValidationCommand_DB()
        {
            string Configuration = "Baseline.DB.config.xml";
            string ServiceAccountsPassword = "Olymp1c$2012";

            string BuildLocation = $@"{RETAINED_RELEASE_WORKING_DIR}\Deployment";
            string RigName = "DeploymentBaseline.RikDev";
            string DriveLetter = "D";
            string LogPath = $@"{RETAINED_RELEASE_WORKING_DIR}\devlogs\";
            string EnvironmentType = "VCloud";

            //bool LocalDebug = true;
            //IList<string> Groups = new List<string>();
            //IList<string> Servers = new List<string>();
            //string Partition = "";
            //bool RemoveMappings = false;            
            
            Invoke_StartPostDeploymentValidationCommand(LogPath, DriveLetter, BuildLocation, Configuration, RigName, EnvironmentType, ServiceAccountsPassword);
        }
        
        private void Invoke_StartPostDeploymentValidationCommand(string LogPath, string DriveLetter, string BuildLocation, string Configuration, string RigName,
                string EnvironmentType, string ServiceAccountsPassword,
                bool LocalDebug = true, IList<string> Groups = null, IList<string> Servers = null, string Partition = "")
        {
            bool? result = null;
            try
            {
                if (string.IsNullOrEmpty(LogPath))
                {
                    LogPath = $@"{DriveLetter}:\Deploy\Logs";
                }

                //var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);
                var logger = new ConsoleLogger();

                var parameterService = new ParameterService(logger);

                var builder = string.IsNullOrWhiteSpace(BuildLocation) ? new RootPathBuilder(@"D:\Deploy\DropFolder") : new RootPathBuilder(BuildLocation)
                {
                    IsLocalDebugMode = LocalDebug,
                    OutputDirectory = LogPath
                };

                var parameters = new DeploymentOperationParameters
                {
                    Groups = Groups ?? new List<string>(),
                    Servers = Servers ?? new List<string>(),
                    DecryptionPassword = ServiceAccountsPassword,
                    DeploymentConfigFileName = Configuration,
                    DriveLetter = DriveLetter,
                    Username = "FAELAB\tfsbuild", // Credential.UserName,
                    Password = ServiceAccountsPassword // Credential.GetNetworkCredential().Password
                };

                switch (EnvironmentType)
                {
                    case "VCloud":
                        parameters.Platform = DeploymentPlatform.VCloud;
                        parameters.RigName = RigName;
                        break;
                    case "Azure":
                        parameters.Platform = DeploymentPlatform.Azure;
                        parameters.RigName = RigName;
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