using System;
using Deployment.Common;
using Deployment.Common.Xml;
using Deployment.Domain.Operations.DomainModelFactory;
using Deployment.Domain.Roles;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class SsisSetupFactoryTests : DomainOperationsTestBase
    {
        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.SsisSetup";
            Body = "<SsisSetup></SsisSetup>";
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("SsisSetup")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();
            var factory = new SsisSetupFactory("default");
            Assert.IsTrue(factory.IsResponsibleFor(element));
        }
        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("SsisSetup")]
        public void TestValidatesNonResponsibility()
        {
            RoleName = "Invalid";
            var element = GenerateServerRoleXml();
            var factory = new SsisSetupFactory("default");
            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("SsisSetup")]
        public void TestReadsCommonRole()
        {
            Body = "<SsisSetup SSISDBInstance='Inst1' />";
            var element = GenerateServerRoleXml();

            var factory = new SsisSetupFactory("default");

            var validationResult = new ValidationResult();
            var item = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(item);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("SsisSetup")]
        public void TestOverridesSsisDbInstance()
        {
            Body = "<SsisSetup SSISDBInstance='Inst1' />";
            var element = GenerateServerRoleXml();

            var factory = new SsisSetupFactory("default");

            var validationResult = new ValidationResult();
            var item = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(item);


            var baseString =
                            @"<ServerRole xmlns='{0}' Name='{1}' Include='Include' Description='Description' SSISDBInstance='Override'></ServerRole>";
            element = XmlHelper.CreateXElement(string.Format(baseString, Namespaces.CommonRole.XmlNamespace, RoleName));
            var role = factory.ApplyOverrides(item, element, ref validationResult) as SsisSetup;
            Assert.IsTrue(role.SsisDbInstance.Equals("Override", StringComparison.InvariantCultureIgnoreCase));
        }
    }
}