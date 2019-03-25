using System;
using System.Xml.Linq;
using Deployment.Common;
using Deployment.Common.Xml;
using Deployment.Domain.Operations.DomainModelFactory;
using Deployment.Domain.Roles;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests.DomainModelFactory
{
    [TestClass]
    public class WebServicePostDeployFactoryTests : DomainOperationsTestBase
    {
        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.PostDeploy";
            Body = "<WebServicePostDeploy></WebServicePostDeploy>";
            Groups = "GroupTest";
            BaseRoleString = @"<PostDeployRole xmlns='{0}' Name='{1}' Description='Start MasterData API' Include='MasterData.Api.Start' Groups='{2}'>{3}</PostDeployRole>";
        }

        protected override XElement GenerateServerRoleXml()
        {
            return XmlHelper.CreateXElement(string.Format(BaseRoleString, Namespaces.CommonRole.XmlNamespace, RoleName, Groups, Body));
        }

        private const string CommonXml = @"<WebServicePostDeploy PortNumber='8734' WebServicePath='status' Timeout='30' />";

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("WebServicePostDeploy")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new WebServicePostDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("WebServicePostDeploy")]
        public void TestValidatesNonResponsibility()
        {
            var invalidRole = string.Format(
                @"<PostDeployRole xmlns='{0}' Name='TFL.PostDeploy_INVALID' Description='Start MasterData API' Include='MasterData.Api.Start' Groups='{1}'>{2}</PostDeployRole>",
                Namespaces.CommonRole.XmlNamespace, Groups, Body);

            var element = XmlHelper.CreateXElement(invalidRole);

            var factory = new WebServicePostDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("WebServicePostDeploy")]
        public void TestReadsCommonRole()
        {
            var factory = new WebServicePostDeployFactory("default");

            Body = CommonXml;
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var baseRole = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(baseRole);

            var webServicePostDeploy = baseRole as WebServicePostDeploy;
            Assert.IsNotNull(webServicePostDeploy);
            Assert.IsTrue(webServicePostDeploy.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));

            Assert.IsFalse(string.IsNullOrWhiteSpace(webServicePostDeploy.WebServicePath));
            Assert.IsFalse(string.IsNullOrWhiteSpace(webServicePostDeploy.Configuration));
            Assert.IsFalse(string.IsNullOrWhiteSpace(webServicePostDeploy.Description));
            Assert.IsFalse(string.IsNullOrWhiteSpace(webServicePostDeploy.Include));
            Assert.IsFalse(string.IsNullOrWhiteSpace(webServicePostDeploy.Name));
            Assert.IsFalse(string.IsNullOrWhiteSpace(webServicePostDeploy.RoleType));

            Assert.IsTrue(webServicePostDeploy.PortNumber > 0);
            Assert.IsTrue(webServicePostDeploy.Timeout > 0);

            Assert.IsNotNull(webServicePostDeploy.Groups);
            Assert.IsTrue(webServicePostDeploy.Groups.Count > 0);
        }
    }
}