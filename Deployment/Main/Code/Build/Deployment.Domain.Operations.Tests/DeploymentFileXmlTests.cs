using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Deployment.Common;
using Deployment.Common.Exceptions;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Parameters;
using Deployment.Domain.Roles;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Moq;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class DeploymentFileXmlTests
    {
        public TestContext TestContext { get; set; }

        [ClassInitialize]
        public static void DeploymentFileXmlReader_ClassInitialise(TestContext context)
        {
            File.Copy(Path.Combine(context.TestDeploymentDir, "Invalid.CommonRoles.xml"),
                Path.Combine(context.TestDeploymentDir, "Scripts", "Invalid.CommonRoles.xml"),
                true);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Config")]
        [TestCategory("Unit")]
        public void TestAllConfigSchemas()
        {
            var exclusionList = new List<string>
            {
                "FG2.Functional.FromConfig.xml",
                "FTDEVP004.DB.xml",
                "Integration.REFUNDS.xml",
                "RSP.DefaultInstance.Database.xml",
                "FAE.DevInt.DbOnly.xml"
                // "SSO.Azure.Functional.xml"
            };

            //Comment/Uncomment contents for debugging purposes only.
            // ReSharper disable once CollectionNeverUpdated.Local
            var inclusionList = new List<string>
            {
                //"DevInt2.Database.xml",
            };

            try
            {
                var scriptsPath = Path.Combine(TestContext.TestDeploymentDir, "Scripts");

                var xmlFiles = Directory.EnumerateFiles(scriptsPath, "*.xml", SearchOption.TopDirectoryOnly)
                    .Select(Path.GetFileName)
                    .Where(f => (inclusionList.IsNullOrEmpty() || inclusionList.Contains(f)) && !exclusionList.Contains(f) && !f.Contains("Invalid") && !f.Contains("Common"));

                var exceptionMessagesBag = new ConcurrentBag<string>();

                var options = new ParallelOptions();
                //options.MaxDegreeOfParallelism = 1; //Comment/Uncomment for debugging purposes only.

                Parallel.ForEach(xmlFiles, options, file =>
                {
                    try
                    {
                        var result = AssertConfigFileIsValid(file);
                        //if (file.Length % 2 == 0) throw new Exception("If you want to see how this test fails, uncomment this line please.");
                        TestContext.WriteLine("XML File {0} is a valid deployment config.", file);
                    }
                    catch (AggregateException aex)
                    {
                        aex.Flatten().InnerExceptions.ForEach(ex =>
                        {
                            exceptionMessagesBag.Add(
                                "Exception thrown while validating file: " + file + Environment.NewLine +
                                ex.GetType().FullName + Environment.NewLine +
                                "Message :" + ex.Message + Environment.NewLine +
                                "Source :" + ex.Source + Environment.NewLine +
                                "Stack Trace :" + ex.StackTrace + Environment.NewLine +
                                "TargetSite :" + ex.TargetSite + Environment.NewLine
                            );
                        });
                    }
                    catch (Exception exception)
                    {
                        while (exception != null)
                        {
                            exceptionMessagesBag.Add(
                                "Exception thrown while validating file: " + file + Environment.NewLine +
                                exception.GetType().FullName + Environment.NewLine +
                                "Message :" + exception.Message + Environment.NewLine +
                                "Source :" + exception.Source + Environment.NewLine +
                                "Stack Trace :" + exception.StackTrace + Environment.NewLine +
                                "TargetSite :" + exception.TargetSite + Environment.NewLine
                            );

                            exception = exception.InnerException;
                            if (exception != null)
                            {
                                exceptionMessagesBag.Add("--- INNER EXCEPTION ---");
                            }
                        }
                    }
                });

                if (exceptionMessagesBag.Count > 0)
                    Assert.Fail(string.Join(Environment.NewLine, exceptionMessagesBag.ToArray()));
            }
            catch (Exception ex)
            {
                Assert.Fail("Test Exception: {0}", ex);
            }
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Config")]
        public void TestXmlReaderReadsBaselineConfig()
        {
            var dp = new DeploymentParameters();
            dp.Add("Key1", "Value1");
            dp.Add("RSP_ReportingRWDatabaseConnectionString", "Value2");
            dp.Add("RSP_FAEDatabaseConnectionString", "Value3");
            dp.Add("Deployment_ServiceBusConnectionString", "Value4");
            dp.Add("Baseline_SimpleDBConnectionString", "Value5");
            dp.Add("Baseline_SbusMainConnectionString", "Value6");
            dp.Add("Baseline_LogPath1", "Dummy");
            dp.Add("Baseline_ArchivePath1", "Dummy");

            var mock = new Mock<IParameterService>();
            mock.Setup(
                    m => m.ParseDeploymentParameters(It.IsAny<IDeploymentPathBuilder>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<List<ICIBasePathBuilder>>(), It.IsAny<string>(), It.IsAny<PlaceholderMappings>(), It.IsAny<RigManifest>()))
                .Returns(dp);

            AssertDeploymentIsValid("Baseline.Apps.config.xml", mock.Object);
            AssertDeploymentIsValid("Baseline.DB.config.xml", mock.Object);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Config")]
        public void TestXmlReaderReadsIntegrationConfig()
        {
            const string targetConfig = "Integration.TSRig.VC.xml";
            var deployment = AssertDeploymentIsValid(targetConfig);

            // Verify the resultant 'config' object
            Assert.AreEqual("TSRig", deployment.Environment, "Environment is incorrect");

            /* Note the deployment object no longer has service accounts composed within it.
            ServiceAccount account = config.ServiceAccounts.GetAccount("CACCServiceAccount");
            Assert.IsNotNull(account, "Service account 'CACCServiceAccount' not found");
            Assert.AreEqual(@"faelab\zsvccacc", account.FullUserName, "User name is incorrect");
            Assert.AreEqual(@"Pa55word", account.Password, "Password is incorrect");
            */

            //// Web deploy
            var cas1 = deployment.Machines.FirstOrDefault(m => m.Name == "TS-CAS1");
            ////Machine machine = (from x in config.Machines where x.Name == "TS-CAS1" select x).FirstOrDefault();
            //Assert.IsNotNull(cas1, "Machine 'TS-CAS1' does not exist");
            //var deploymentRoles = deployment.Machines.SelectMany(m => m.DeploymentRoles);
            //var cascPortal = deploymentRoles.FirstOrDefault(r => r.Description == "CACC Portal") as WebDeploy;
            //Assert.IsNotNull(cascPortal, "Role 'CACC Portal' does not exist");
            //Assert.AreEqual(cascPortal.Package.Name, "CSC Web", "Package name incorrect");
            //Assert.AreEqual(cascPortal.Site.Port, 80, "Port incorrect");
            //Assert.AreEqual(cascPortal.Site.Name, "Default Web Site", "Site name incorrect");
            //Assert.AreEqual(cascPortal.AppPool.Name, "CSCPortal", "App pool name incorrect");
            //Assert.AreEqual(cascPortal.AppPool.ServiceAccount, "NetworkService",
            //    "App set to use incorrect Service Account");
            //Assert.AreEqual(cascPortal.Site.PhysicalPath, @"D:\TFL\CACC\CSCPortal", "Physical path incorrect");
            //Assert.AreEqual(cascPortal.RegistryKey, @"Software\TfL\CASC\CustomerPortal", "Registry key is incorrect");
            //Assert.AreEqual(cascPortal.AssemblyToVersionFrom, "TfL.CSC.Web.dll", "AssemblyToVersionFrom is incorrect");

            // IIS role
            //Assert.IsTrue(cas1.DeploymentRoles.Where(r => r is IisSetupDeploy).CountEqualTo(1),
            //    "Should be a IIS deployment role on TS-CAS1");

            // Create folder
            var fileSystemRoles = cas1.DeploymentRoles.OfType<FileSystemDeploy>();
            Assert.IsTrue(fileSystemRoles.CountEqualTo(1), "Should be 1 file system role on TS-CAS1");
            var createFolders = fileSystemRoles.First().CreateFolderDeploys;
            Assert.AreEqual(createFolders.FirstOrDefault()?.TargetPath, @"\{DriveLetter}$\TFL\CACC\emailqueue",
                "Target path incorrect");

            // Copy item
            var db2 = deployment.Machines.SingleOrDefault(m => m.Name == "TS-DB2");
            Assert.IsNotNull(db2, "Machine 'TS-DB2' does not exist");
            fileSystemRoles = cas1.DeploymentRoles.OfType<FileSystemDeploy>();
            Assert.AreEqual(2, fileSystemRoles.First().CreateFolderDeploys.Count(),
                "Should be 2 file system roles on TS-DB2");

            // Database role
            var db1 = deployment.Machines.FirstOrDefault(m => m.Name == "TS-DB1");
            Assert.IsNotNull(db1, "Machine 'TS-DB1' does not exist");
            Assert.IsTrue(db1.DeploymentMachine, "Machine should be deployment machine");
            var faeDbRole = db1.DatabaseRoles.SingleOrDefault(r => r.Description == "FAE Database");
            Assert.IsNotNull(faeDbRole, "Role 'FAE Database' does not exist");
            var dbRole = (DatabaseDeploy)faeDbRole;
            Assert.AreEqual("FAE", dbRole.TargetDatabase, "Target database name incorrect");
            Assert.AreEqual("Inst1", dbRole.DatabaseInstance, "Database instance incorrect");

            // Service deploy and common roles
            var fae2 = deployment.Machines.FirstOrDefault(m => m.Name == "TS-FAE2");
            Assert.IsNotNull(fae2, "Machine 'TS-FAE2' does not exist");
            var serviceRole =
                fae2.DeploymentRoles.OfType<ServiceDeploy>().FirstOrDefault(r => r.Description == "FAE Engine");
            Assert.IsNotNull(serviceRole, "Role 'FAE Engine' does not exist");
            Assert.AreEqual(@"{DriveLetter}:\TFL\FAE\PipelineHost\", serviceRole.MsiDeploy.InstallationLocation,
                "Install location incorrect");
            Assert.AreEqual(4, serviceRole.MsiDeploy.Configs.Count, "Number configs incorrect");
            Assert.AreEqual(@"\TFL\FAE\PipelineHost",
                serviceRole.MsiDeploy.Configs.SingleOrDefault(c => c.Name == "PipelineHost.exe.config")?.Target,
                "Config data incorrect");
            Assert.AreEqual(1, serviceRole.Services.Count, "Services data is incorrect");

            var pipelineHost = serviceRole.Services.FirstOrDefault(s => s.Name == "FAE PipelineHost Service");
            Assert.IsNotNull(pipelineHost, "Cannot find pipeline host service");
            Assert.AreEqual("FAEServiceAccount", pipelineHost.Account.LookupName, "Service identity is incorrect");
            Assert.AreEqual(WindowsServiceStartupType.AutomaticDelayed, pipelineHost.StartupType,
                "Windows service start up type is incorrect");

            //Pare machine exists
            //ToDo need to add some MSI tests
            var pare1 = deployment.Machines.SingleOrDefault(m => m.Name == "TS-PARE1");
            Assert.IsNotNull(pare1, "Machine 'TS-PARE1' does not exist");

            //Service broker test
            Assert.AreEqual(4, deployment.CustomTests.Count, "Unexpected number of custom tests found");
            var customTest = deployment.CustomTests[0];
            Assert.IsTrue(customTest is ServiceBrokerTest, "First test is not a service broker");
            var sbTest = customTest as ServiceBrokerTest;
            Assert.AreEqual(2, sbTest.Tests.Count);
            Assert.AreEqual("TS-DB1", sbTest.Tests[0].DatabaseServer, "database server 1 incorrect");
            Assert.AreEqual("Pcs", sbTest.Tests[1].TargetDatabase, "target database 2 incorrect");
            Assert.AreEqual("Inst2", sbTest.Tests[1].DatabaseInstance, "target database 2 incorrect");
            Assert.IsFalse(string.IsNullOrEmpty(sbTest.Tests[0].SqlScript), "Sql in service broker test incorrect");
            Assert.IsFalse(string.IsNullOrEmpty(sbTest.Tests[1].SqlScript), "Sql in service broker test incorrect");
        }


        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("Config")]
        public void TestXmlReaderMissingCommonRole()
        {
            const string testConfig = "InvalidCommonRoles1.config.xml";
            var expectedErrors = new List<string>
            {
                "Common include file 'MissingCommonRole.xml' was not found."
            };

            ExecuteInvalidCommonRoleTest(testConfig, expectedErrors);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("Config")]
        public void TestXmlReaderInvalidInclude()
        {
            const string testConfig = "InvalidCommonRoles9.config.xml";
            var expectedErrors = new List<string>
            {
                "Machine 'TS-FAE3' contains an invalid Include attribute 'FAE.Engine.Serv'"
            };

            ExecuteInvalidCommonRoleTest(testConfig, expectedErrors);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Config")]
        public void TestXmlReaderInvalidAttribute()
        {
            const string testConfig = "InvalidCommonRoles4.config.xml";
            var expectedErrors = new List<string>
            {
                "The 'Name' attribute is not declared."
            };

            ExecuteInvalidCommonRoleTest(testConfig, expectedErrors);
        }


        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("Config")]
        public void TestXmlReaderServiceDeployMsiMustHaveAnIdOrAnUpgradeCode()
        {
            const string testConfig = "InvalidCommonRoles5.config.xml";
            var expectedErrors = new List<string>
            {
                "ServerRole 'TFL.ServiceDeploy' (Invalid Config - Test Case 5) must have at least one of the following specified [id] (which is the product code) or [UpgradeCode] in the MSI block."
            };
            ExecuteInvalidCommonRoleTest(testConfig, expectedErrors);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("Config")]
        public void TestXmlReaderMsiDeployMsiMustHaveAnIdOrAnUpgradeCode()
        {
            const string testConfig = "InvalidCommonRoles6.config.xml";
            var expectedErrors = new List<string>
            {
                "ServerRole 'TFL.MsiDeploy' (Invalid Config - Test Case 6) must have at least one of the following specified [id] (which is the product code) or [UpgradeCode] in the MSI block."
            };
            ExecuteInvalidCommonRoleTest(testConfig, expectedErrors);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("Config")]
        public void TestXmlReaderServiceDeployMustHaveAConfigSpecified()
        {
            const string testConfig = "InvalidCommonRoles7.config.xml";
            var expectedErrors = new List<string>
            {
                "ServerRole 'TFL.ServiceDeploy' (Invalid Config - Test Case 7) does not specify any configs."
            };
            ExecuteInvalidCommonRoleTest(testConfig, expectedErrors);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("Config")]
        public void TestIncludesCannotContainChildElements()
        {
            const string testConfig = "InvalidCommonRoles8.config.xml";
            var expectedErrors = new List<string>
            {
                "The element 'http://tfl.gov.uk/DeploymentConfig:ServerRole' cannot contain child element 'http://tfl.gov.uk/DeploymentConfig:ServiceDeploy' because the parent element's content model is text only."
            };
            ExecuteInvalidCommonRoleTest(testConfig, expectedErrors);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Config")]
        public void TestXmlReaderRolesExistsWithExpectedDescription()
        {
            var deployment = AssertDeploymentIsValid("Integration.TSRig.VC.xml");

            var databaseRoles = deployment.Machines.SelectMany(m => m.DatabaseRoles).ToList();
            AssertDatabaseRoleExistsByDescription(databaseRoles, "PARE Main Schema");
            AssertDatabaseRoleExistsByDescription(databaseRoles, "FAE Database");
            AssertDatabaseRoleExistsByDescription(databaseRoles, "CSC Database");
            AssertDatabaseRoleExistsByDescription(databaseRoles, "PARE PCS Common for PCS DB");
            AssertDatabaseRoleExistsByDescription(databaseRoles, "Notification Database");
            AssertDatabaseRoleExistsByDescription(databaseRoles, "SDM Database");
            AssertDatabaseRoleExistsByDescription(databaseRoles, "RSP Database");
            AssertDatabaseRoleExistsByDescription(databaseRoles, "SSO Database");
            AssertDatabaseRoleExistsByDescription(databaseRoles, "TravelStore Database");

            var deploymentRoles = deployment.Machines.SelectMany(m => m.DeploymentRoles).ToList();
            AssertDeploymentRoleExistsByDescription(deploymentRoles, "PareAuthorisationGatewayServiceInstaller");
            AssertDeploymentRoleExistsByDescription(deploymentRoles, "FAE Controller");
            AssertDeploymentRoleExistsByDescription(deploymentRoles, "FAE Engine");
            AssertDeploymentRoleExistsByDescription(deploymentRoles, "Notifications File Processor");
            AssertDeploymentRoleExistsByDescription(deploymentRoles, "Pare.TravelTokenService");
            AssertDeploymentRoleExistsByDescription(deploymentRoles, "SSO Website");
            AssertDeploymentRoleExistsByDescription(deploymentRoles, "FTM IM File System");
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("Config")]
        public void TestXmlReaderInvalidSchema()
        {
            const string testConfig = "InvalidSchema.config.xml";
            var expectedErrors = new List<string>
            {
                "The 'MachineName' attribute is not declared.",
                "The required attribute 'Include' is missing."
            };
            ExecuteInvalidCommonRoleTest(testConfig, expectedErrors);
        }

        private IDomainModelValidator AssertConfigFileIsValid(string configName)
        {
            var deploymentResult = GetDeployment(configName);

            //assert
            Assert.IsNotNull(deploymentResult.Item1);

            Assert.IsTrue(deploymentResult.Item1.ValidationResult.Result);

            return deploymentResult.Item1;
        }

        private Deployment AssertDeploymentIsValid(string configName, IParameterService parameterService = null)
        {
            var deploymentResult = GetDeployment(configName, false, parameterService);

            //assert
            Assert.IsNotNull(deploymentResult.Item1);
            Assert.IsNotNull(deploymentResult.Item2);

            Assert.IsTrue(deploymentResult.Item1.ValidationResult.Result);

            return deploymentResult.Item2;
        }

        private Tuple<IDomainModelValidator, Deployment> GetDeployment(string configName, bool configValidateOnly = true, IParameterService parameterService = null)
        {
            var logger = new TestContextLogger(TestContext);
            var pathBuilder = new RootPathBuilder(TestContext.TestDeploymentDir, logger) {IsLocalDebugMode = true};
            var pathBuilders = pathBuilder.CreateChildPathBuilders(configName);
            var factoryBuilder = new DomainModelFactoryBuilder();

            var validator = new DomainModelValidator(logger);

            if (configValidateOnly)
            {
                var result = validator.ValidateDomainModelFile(Path.Combine(pathBuilders.Item1.ScriptsRelativeDirectory, configName));
                return new Tuple<IDomainModelValidator, Deployment>(validator, null);
            }

            if(parameterService == null)
                parameterService = new ParameterService(logger);

            var deploymentService = new DeploymentService(logger, parameterService);

            var deployment = deploymentService.GetDeployment(validator, factoryBuilder, pathBuilders.Item1, pathBuilders.Item2);

            return new Tuple<IDomainModelValidator, Deployment>(validator, deployment);
        }

        private void AssertDeploymentRoleExistsByDescription(IList<IDeploymentRole> deploymentRoles,
            string roleDescription)
        {
            var role = deploymentRoles.FirstOrDefault(d => d.Description == roleDescription);
            Assert.IsNotNull(role);
        }

        private void AssertDatabaseRoleExistsByDescription(IList<IDatabaseRole> databaseRoles, string roleDescription)
        {
            var role = databaseRoles.FirstOrDefault(d => d.Description == roleDescription);
            Assert.IsNotNull(role);
        }

        private void ExecuteInvalidCommonRoleTest(string testConfigFile, IList<string> expectedErrorStrings)
        {
            File.Copy(Path.Combine(TestContext.TestDeploymentDir, testConfigFile),
                Path.Combine(TestContext.TestDeploymentDir, "Scripts", testConfigFile));

            //Building a domain with invalid configs will always throw
            try
            {
                var deploymentInfo = GetDeployment(testConfigFile, false);
                Assert.Fail("Common Include tests should have failed.");
            }
            catch (ValidationException ex)
            {
                var valid = expectedErrorStrings.Aggregate(true,
                    (current, errorString) => current && ex.ValidationErrors.Contains(errorString));

                Assert.IsTrue(valid, "Fail message does not indicate expected validation failure(s).");
            }
        }
    }
}