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
    public class PreRequisiteDeployFactoryTests : DomainOperationsTestBase
    {
        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.ServerPrerequisite";
            Body = "<WindowsServicePrerequisite></WindowsServicePrerequisite>";
            Groups = "GroupTest";
            BaseRoleString = @"<ServerRole xmlns='{0}' Name='{1}' Description='CheckSqlIntegrationService' Include='CheckSqlIntegrationService' Groups='{2}'>{3}</ServerRole>";
        }

        protected override XElement GenerateServerRoleXml()
        {
            return XmlHelper.CreateXElement(string.Format(BaseRoleString, Namespaces.CommonRole.XmlNamespace, RoleName, Groups, Body));
        }

        private const string CommonXml = @"<WindowsServicePrerequisite ServiceName='MsDtsServer110' State='Running' Action='Fix' />";


        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("PreRequisiteDeploy")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new PreRequisiteDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("PreRequisiteDeploy")]
        public void TestValidatesNonResponsibility()
        {
            var invalidRole = string.Format(
                @"<ServerRole xmlns='{0}' Name='TFL.ServerPrerequisite_INVALID' Description='CheckSqlIntegrationService' Include='CheckSqlIntegrationService' Groups='{1}'>{2}</ServerRole>",
                Namespaces.CommonRole.XmlNamespace, Groups, Body);

            var element = XmlHelper.CreateXElement(invalidRole);

            var factory = new PreRequisiteDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }



        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("WebServicePostDeploy")]
        public void TestReadsCommonRole()
        {
            var factory = new PreRequisiteDeployFactory("default");

            Body = CommonXml;
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var baseRole = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(baseRole);

            var webServicePostDeploy = baseRole as PreRequisiteDeploy;
            Assert.IsNotNull(webServicePostDeploy);
            Assert.IsTrue(webServicePostDeploy.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));

            //Assert.IsFalse(string.IsNullOrWhiteSpace(webServicePostDeploy.WebServicePath));
            Assert.IsFalse(string.IsNullOrWhiteSpace(webServicePostDeploy.Configuration));
            Assert.IsFalse(string.IsNullOrWhiteSpace(webServicePostDeploy.Description));
            Assert.IsFalse(string.IsNullOrWhiteSpace(webServicePostDeploy.Include));
            Assert.IsFalse(string.IsNullOrWhiteSpace(webServicePostDeploy.Name));
            Assert.IsFalse(string.IsNullOrWhiteSpace(webServicePostDeploy.RoleType));

            Assert.IsNotNull(webServicePostDeploy.Groups);
            Assert.IsTrue(webServicePostDeploy.Groups.Count > 0);

            Assert.IsNotNull(webServicePostDeploy.PreRequisiteRoles);
            Assert.IsTrue(webServicePostDeploy.PreRequisiteRoles.Count > 0);

            Assert.IsNotNull(webServicePostDeploy.WindowsServicePreRequisites);
            Assert.IsTrue(webServicePostDeploy.WindowsServicePreRequisites.Count > 0);
        }
    }
}
