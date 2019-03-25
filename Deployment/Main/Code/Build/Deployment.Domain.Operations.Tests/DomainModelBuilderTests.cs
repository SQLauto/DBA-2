using System;
using System.Collections.Generic;
using System.Linq;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Parameters;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;
using Moq;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class DomainModelBuilderTests : DomainOperationsTestBase
    {
        private const string FileToParse = @"Baseline.Apps.config.xml";
        private const string DbFileToParse = @"Baseline.DB.config.xml";
        private IParameterService _parameterServiceMock;
        private IBasePathBuilder _pathBuilderMock;

        [TestInitialize]
        public void SetUp()
        {
            var mock = new Mock<IParameterService>();
            mock.Setup(
                    m => m.ParseDeploymentParameters(It.IsAny<IDeploymentPathBuilder>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<List<ICIBasePathBuilder>>(), It.IsAny<string>(), It.IsAny<PlaceholderMappings>(), It.IsAny<RigManifest>()))
                .Returns(GetDeploymentParameters());

            _parameterServiceMock = mock.Object;
            _pathBuilderMock = new Mock<IBasePathBuilder>().Object;
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
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ModelBuilder")]
        [DeploymentItem(@"Deploy\Scripts\Baseline.Apps.config.xml")]
        [DeploymentItem(@"Deploy\Scripts\Baseline.CommonRoles.xml")]
        public void TestCanBuildModel()
        {
            //arrange
            var logger = new TestContextLogger(TestContext);
            var validator = new DomainModelValidator(logger);
            var pathBuilder = new RootPathBuilder(TestContext.DeploymentDirectory) { IsLocalDebugMode = true };
            var pathBuilders = pathBuilder.CreateChildPathBuilders(FileToParse);

            var builder = new DomainModelBuilder(validator, new DomainModelFactoryBuilder(), pathBuilders.Item1, pathBuilders.Item2, _parameterServiceMock, logger);

            //act
            var deployment = builder.BuildDomain();

            // assert
            Assert.IsNotNull(deployment);
            Assert.IsNotNull(deployment.Machines);
            Assert.IsTrue(deployment.Machines.Any());
            Assert.AreEqual(3, deployment.Machines.Count);

            var machine = deployment.Machines.First(m => m.Name.Equals("TS-DB1"));
            Assert.AreEqual(15, machine.DeploymentRoles.Count);

            machine = deployment.Machines.First(m => m.Name.Equals("TS-CAS1"));
            Assert.AreEqual(10, machine.DeploymentRoles.Count);

            machine = deployment.Machines.First(m => m.Name.Equals("TS-CIS1"));
            Assert.AreEqual(1, machine.PreDeploymentRoles.Count);
            Assert.AreEqual(16, machine.DeploymentRoles.Count);

            Assert.AreEqual(1, deployment.CustomTests.Count);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ModelBuilder")]
        [DeploymentItem(@"Deploy\Scripts\Baseline.Apps.config.xml")]
        [DeploymentItem(@"Deploy\Scripts\Baseline.CommonRoles.xml")]
        public void TestCanBuildAndFilterModel()
        {
            //arrange
            var logger = new TestContextLogger(TestContext);
            var validator = new DomainModelValidator(logger);
            var pathBuilder = new RootPathBuilder(TestContext.DeploymentDirectory, logger) { IsLocalDebugMode = true };
            var pathBuilders = pathBuilder.CreateChildPathBuilders(FileToParse);

            var builder = new DomainModelBuilder(validator, new DomainModelFactoryBuilder(), pathBuilders.Item1, pathBuilders.Item2, _parameterServiceMock, logger);

            //act
            var deployment = builder.BuildDomain();

            // assert
            Assert.IsNotNull(deployment);
            Assert.IsNotNull(deployment.Machines);
            Assert.IsTrue(deployment.Machines.Any());
            Assert.AreEqual(3, deployment.Machines.Count);

            var machine = deployment.Machines.First(m => m.Name.Equals("TS-DB1"));
            Assert.AreEqual(15, machine.DeploymentRoles.Count);

           var deploymentService = new DeploymentService(logger, _parameterServiceMock);

            var groupsFilter = new GroupFilters(new []{"Win"}, Enumerable.Empty<string>());

            var filtered = deploymentService.FilterDeployment(deployment, new List<string>(), groupsFilter);

            machine = filtered.Machines.First(m => m.Name.Equals("TS-DB1"));
            Assert.AreEqual(14, machine.DeploymentRoles.Count);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ModelBuilder")]
        [DeploymentItem(@"Deploy\Scripts\Baseline.DB.config.xml")]
        [DeploymentItem(@"Deploy\Scripts\Baseline.CommonRoles.xml")]
        public void TestCanBuildModelWithDataBase()
        {
            //arrange
            var logger = new TestContextLogger(TestContext);
            var validator = new DomainModelValidator(logger);
            var pathBuilder = new RootPathBuilder(TestContext.DeploymentDirectory) { IsLocalDebugMode = true };
            var pathBuilders = pathBuilder.CreateChildPathBuilders(DbFileToParse);

            var builder = new DomainModelBuilder(validator, new DomainModelFactoryBuilder(), pathBuilders.Item1, pathBuilders.Item2, _parameterServiceMock, logger);

            //act
            var deployment = builder.BuildDomain();

            // assert
            Assert.IsNotNull(deployment);
            Assert.IsNotNull(deployment.Machines);
            Assert.IsTrue(deployment.Machines.Any());
            Assert.AreEqual(1, deployment.Machines.Count);

            var machine = deployment.Machines.First(m => m.Name.Equals("TS-DB1"));
            Assert.IsTrue(machine.PreDeploymentRoles.Count > 0);
            Assert.IsTrue(machine.DatabaseRoles.Count > 0);


        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ModelBuilder")]
        public void TestValidatesConstructorArgs()
        {
            //arrange
            var logger = new TestContextLogger(TestContext);
            var validator = new DomainModelValidator(logger);
            var pathBuilder = new RootPathBuilder(TestContext.DeploymentDirectory) { IsLocalDebugMode = true };
            var pathBuilders = pathBuilder.CreateChildPathBuilders(FileToParse);
            var factoryBuilder = new DomainModelFactoryBuilder();

            Assert.Throws<ArgumentNullException>(() => new DomainModelBuilder(null, factoryBuilder, pathBuilders.Item1, pathBuilders.Item2, _parameterServiceMock, logger), "Value cannot be null.\r\nParameter name: validator");
            Assert.Throws<ArgumentException>(() => new DomainModelBuilder(validator, null, pathBuilders.Item1, pathBuilders.Item2, _parameterServiceMock, logger), "Value cannot be null.\r\nParameter name: factoryBuilder");
            Assert.Throws<ArgumentException>(() => new DomainModelBuilder(validator, factoryBuilder, null, pathBuilders.Item2, _parameterServiceMock, logger), "Value cannot be null.\r\nParameter name: deploymentPathBuilder");
            Assert.Throws<ArgumentException>(() => new DomainModelBuilder(validator, factoryBuilder, pathBuilders.Item1, null, _parameterServiceMock, logger), "Value cannot be null.\r\nParameter name: ciPathBuilders");
            Assert.Throws<ArgumentException>(() => new DomainModelBuilder(validator, factoryBuilder, pathBuilders.Item1, pathBuilders.Item2, null, logger), "Value cannot be null.\r\nParameter name: parameterService");
        }
    }
}