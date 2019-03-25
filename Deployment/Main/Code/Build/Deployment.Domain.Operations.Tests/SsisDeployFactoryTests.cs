using System;
using System.Collections.Generic;
using Deployment.Domain.Operations.DomainModelFactory;
using Deployment.Common;
using Deployment.Domain.Parameters;
using Deployment.Domain.Roles;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Moq;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class SsisDeployFactoryTests : DomainOperationsTestBase
    {
        private IParameterService _parameterServiceMock;
        private IRootPathBuilder _pathBuilderMock;

        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.SsisDeploy";
            Body = "<SsisDeploy></SsisDeploy>";

            _pathBuilderMock = new Mock<IRootPathBuilder>().Object;

            var mock = new Mock<IParameterService>();
            mock.Setup(
                    m => m.ParseDeploymentParameters(It.IsAny<IDeploymentPathBuilder>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<List<ICIBasePathBuilder>>(), It.IsAny<string>(), It.IsAny<PlaceholderMappings>(), It.IsAny<RigManifest>()))
                .Returns(GetDeploymentParameters());

            _parameterServiceMock = mock.Object;

            

        }

        private DeploymentParameters GetDeploymentParameters()
        {
            var dp = new DeploymentParameters();
            dp.Add("RSP_Test1", "Value1");
            dp.Add("RSP_Test2", "Value2");

            return dp;
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("SsisDeploy")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new SsisDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("SsisDeploy")]
        public void TestValidatesNonResponsibility()
        {
            RoleName = "Invalid";
            var element = GenerateServerRoleXml();

            var factory = new SsisDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("SsisDeploy")]
        public void TestValidatesDeployMode()
        {
            Body = "<SsisDeploy Name='Test'><DeployMode>WIZ</DeployMode><Project><Name>SimpleSSISPackage</Name><SsisFile>SimpleSSISPackage.ispac</SsisFile><Type>ISPAC</Type></Project></SsisDeploy>";
            var element = GenerateServerRoleXml();

            var factory = new SsisDeployFactory("default");

            var validationResult = new ValidationResult();
            var item = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(item);
        }

        private const string CommonXml = @"
    <DeployMode>WIZ</DeployMode>
    <SSISEnvironment>RspAllocation</SSISEnvironment>
    <SSISFolder>RSP</SSISFolder>
    <DatabaseInstance>XXX</DatabaseInstance>
    <Project>
        <Name>TestProject</Name>
        <SsisFile>SimpleSSISPackage.ispac</SsisFile>
        <Type>ISPAC</Type>
        <Packages>
            <Package Name=""RSP.dtsx"" />
        </Packages>
        <parameters>
            <parameter name=""Key1"" value=""D:\TFL\RSP\Final\"" type=""string"" description=""Final folder location."" />
            <parameter name=""Key2"" value=""$(RSP_Test2)"" type=""string"" description=""Reporting database"" />
        </parameters>
    </Project>
    <TestInfo SqlUserName=""tfsbuild"" SqlPassword=""xxx"" />";
    }
}
