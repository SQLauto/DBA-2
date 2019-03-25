using System;
using Deployment.Common;
using Deployment.Domain.Operations.DomainModelFactory;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class WebDeployFactoryTests : DomainOperationsTestBase
    {
        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.WebDeploy";
            Body = @"<WebDeploy RegistryKey=""Software\TfL\BaseLineX"" Name=""Deployment Baseline Web"">{0}</WebDeploy>";
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("WebDeploy")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new WebDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("WebDeploy")]
        public void TestValidatesNonResponsibility()
        {
            RoleName = "Invalid";
            var element = GenerateServerRoleXml();

            var factory = new WebDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("WebDeploy")]
        public void TestOverridesDefatultConfig()
        {
            var factory = new WebDeployFactory("default");
            Config = "Config='Test1'";

            Body = string.Format(Body, BasicXml);

            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var webDeploy = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(webDeploy);
            Assert.IsFalse(string.IsNullOrWhiteSpace(webDeploy.Configuration));
            Assert.IsTrue(webDeploy.Configuration.Equals("Test1", StringComparison.InvariantCultureIgnoreCase));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("WebDeploy")]
        public void TestValidatesMissingRegistryKeyConfig()
        {
            var factory = new WebDeployFactory("default");

            Body = $@"<WebDeploy Name=""Deployment Baseline Web"">{BasicXml}</WebDeploy>";
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var webDeploy = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsFalse(validationResult.Result));
            Assert.IsNull(webDeploy);
        }

        private const string BasicXml = @"<AppPool>
    <Name>Baseline</Name>
    <ServiceAccount>ApplicationPoolIdentity</ServiceAccount>
 </AppPool>
<Site>
    <Name>Baseline</Name>
    <Port>8698</Port>
    <PhysicalPath>SomePath</PhysicalPath>
</Site>
<Package>
    <Name>CSC Web</Name>
</Package>
<Encryption>
    <Encrypt Section=""PaymentGateway"" />
</Encryption>
<TestInfo>
    <EndPoint></EndPoint>
</TestInfo>";
    }
}