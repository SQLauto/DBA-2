using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Parameters;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Moq;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class DeploymentServiceTests : BaseTest
    {
        private const string FileToParse = @"DeploymentGroups.DeploymentBaseline.xml";
        private IParameterService _parameterServiceMock;

        public TestContext TestContext { get; set; }

        [TestInitialize]
        public void SetUp()
        {
            var mock = new Mock<IParameterService>();
            mock.Setup(
                    m => m.ParseDeploymentParameters(It.IsAny<IDeploymentPathBuilder>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<List<ICIBasePathBuilder>>(), It.IsAny<string>(), It.IsAny<PlaceholderMappings>(), It.IsAny<RigManifest>()))
                .Returns(GetDeploymentParameters());

            _parameterServiceMock = mock.Object;
        }

        private DeploymentParameters GetDeploymentParameters()
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

            return dp;
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("Utility")]
        [DeploymentItem(@"Deploy\Groups\DeploymentGroups.DeploymentBaseline.xml")]
        public void TestValidateGroupFails()
        {
            var logger = new TestContextLogger(TestContext);
            var parameterService = new ParameterService(logger);

            var deploymentService = new DeploymentService(logger, parameterService);

            var groups = new[] {"Test1", "!Test2"};

            //act
            var groupFilters = deploymentService.ValidateGroups(groups, FileToParse);

            Assert.IsNull(groupFilters);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("Utility")]
        [DeploymentItem(@"Deploy\Groups\DeploymentGroups.DeploymentBaseline.xml")]
        public void TestValidateGroupCtor()
        {
            var logger = new TestContextLogger(TestContext);
            var parameterService = new ParameterService(logger);

            var deploymentService = new DeploymentService(logger, parameterService);
            var groups = new[] { "Web", "!Win" };

            //File was not found: DeploymentGroups.DeploymentBaseline.xml

            //Assert
            Assert.Throws<ArgumentException>(() => deploymentService.ValidateGroups(groups, null), "Value cannot be null, empty or whitespace.\r\nParameter name: filePath");
            Assert.Throws<IOException>(() => deploymentService.ValidateGroups(groups, "NotValid.xml"), "Group file NotValid.xml was not found.");
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("Utility")]
        [DeploymentItem(@"Deploy\Groups\DeploymentGroups.DeploymentBaseline.xml")]
        public void TestValidateGroupSucceeds()
        {
            var logger = new TestContextLogger(TestContext);
            var parameterService = new ParameterService(logger);

            var deploymentService = new DeploymentService(logger, parameterService);

            var groups = new[] { "Web", "!Win" };

            //act
            var groupFilters = deploymentService.ValidateGroups(groups, FileToParse);

            Assert.IsNotNull(groupFilters);
            Assert.AreEqual(groupFilters.IncludeGroups.Count, 1);
            Assert.AreEqual(groupFilters.ExcludeGroups.Count, 1);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("Utility")]
        [DeploymentItem(@"Deploy\Groups\DeploymentGroups.DeploymentBaseline.xml")]
        [DeploymentItem(@"Deploy\Scripts\Baseline.Apps.config.xml")]
        [DeploymentItem(@"Deploy\Scripts\Baseline.CommonRoles.xml")]
        public void TestFiltersForGroup()
        {
            var logger = new TestContextLogger(TestContext);

            var deploymentService = new DeploymentService(logger, _parameterServiceMock, true);

            var baseDeployment = deploymentService.GetDeployment(TestContext.DeploymentDirectory, @"Baseline.Apps.config.xml");
            var groups = new[] { "Web" };

            //act
            var groupFilters = deploymentService.ValidateGroups(groups, FileToParse);

            Assert.IsNotNull(groupFilters);
            Assert.AreEqual(1, groupFilters.IncludeGroups.Count);
            Assert.AreEqual(0, groupFilters.ExcludeGroups.Count);

            var allowed = new [] {"Web", "Always"};

            var filteredDeployment = deploymentService.FilterDeployment(baseDeployment, null, groupFilters);

            var any = filteredDeployment.Machines.SelectMany(m => m.DeploymentRoles.SelectMany(g => g.Groups))
                .Any(g => !allowed.Contains(g));

            Assert.IsFalse(any);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("Utility")]
        [DeploymentItem(@"Deploy\Groups\DeploymentGroups.FTP.xml")]
        [DeploymentItem(@"Deploy\Scripts\Integration.TSRig.VC.xml")]
        [DeploymentItem(@"Deploy\Scripts\CommonServerRoles.xml")]
        [DeploymentItem(@"Deploy\Scripts\CommonLabServerRoles.xml")]
        [DeploymentItem(@"Deploy\Scripts\CommonLabDatabaseRoles.xml")]
        [DeploymentItem(@"Deploy\Scripts\CommonDatabaseRoles.xml")]
        [DeploymentItem(@"Deploy\Scripts\SSO.CommonInternalServerRoles.xml")]
        [DeploymentItem(@"Deploy\Scripts\SSO.CommonExternalServerRoles.xml")]
        [DeploymentItem(@"Deploy\Scripts\SSO.CommonLabDatabaseRoles.xml")]
        [DeploymentItem(@"Deploy\Scripts\SSO.CommonDatabaseRoles.xml")]
        [DeploymentItem(@"Deploy\Scripts\CommonMJTDeltasRole.xml")]
        public void TestFilteringRemovesEmptyMachines()
        {
            var logger = new TestContextLogger(TestContext);
            var parameterService = new ParameterService(logger);

            var deploymentService = new DeploymentService(logger, parameterService, true);

            var baseDeployment = deploymentService.GetDeployment(TestContext.DeploymentDirectory, @"Integration.TSRig.VC.xml");
            var groups = new[] { "PARE" };

            //act
            var groupFilters = deploymentService.ValidateGroups(groups, "DeploymentGroups.FTP.xml");

            Assert.IsNotNull(groupFilters);
            Assert.AreEqual(1, groupFilters.IncludeGroups.Count);
            Assert.AreEqual(0, groupFilters.ExcludeGroups.Count);

            var filteredDeployment = deploymentService.FilterDeployment(baseDeployment, null, groupFilters);

            //ensure all machines with empty roles have been removed
            var empty = filteredDeployment.Machines.Where(m => !m.AllRoles().Any()).ToList();

            Assert.AreEqual(0, empty.Count);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("Utility")]
        [DeploymentItem(@"Deploy\Groups\DeploymentGroups.DeploymentBaseline.xml")]
        [DeploymentItem(@"Deploy\Scripts\Baseline.Apps.config.xml")]
        [DeploymentItem(@"Deploy\Scripts\Baseline.CommonRoles.xml")]
        public void TestFiltersForMachine()
        {
            var logger = new TestContextLogger(TestContext);

            var deploymentService = new DeploymentService(logger, _parameterServiceMock, true);

            var baseDeployment = deploymentService.GetDeployment(TestContext.DeploymentDirectory, @"Baseline.Apps.config.xml");
            var machines = new[] { "TS-CAS1" };

            //act
            var filteredDeployment = deploymentService.FilterDeployment(baseDeployment, machines, new GroupFilters());

            Assert.AreEqual(1, filteredDeployment.Machines.Count);
        }
    }
}