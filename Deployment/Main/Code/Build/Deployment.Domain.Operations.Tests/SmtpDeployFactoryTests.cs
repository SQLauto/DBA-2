using Deployment.Common;
using Deployment.Domain.Operations.DomainModelFactory;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class SmtpDeployFactoryTests : DomainOperationsTestBase
    {
        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.SMTPDeploy";
            Body = "<SMTPDeploy></SMTPDeploy>";
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("SMTPDeploy")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new SmtpDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("SMTPDeploy")]
        public void TestValidatesNonResponsibility()
        {
            RoleName = "Invalid";
            var element = GenerateServerRoleXml();

            var factory = new SmtpDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("SMTPDeploy")]
        public void TestValidatesDropLocation()
        {
            var element = GenerateServerRoleXml();

            var factory = new SmtpDeployFactory("default");

            var validationResult = new ValidationResult();
            var domainModel = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsFalse(validationResult.Result));
            Assert.IsNull(domainModel);
        }
    }
}