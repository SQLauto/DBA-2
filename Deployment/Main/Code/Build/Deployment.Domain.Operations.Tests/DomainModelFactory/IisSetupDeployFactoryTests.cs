using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
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
    public class IisSetupDeployFactoryTests : DomainOperationsTestBase
    {
        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.IISSetup";
            Body = string.Empty;
            Groups = "GroupTest";
            BaseRoleString = @"<ServerRole xmlns='{0}' Name='{1}' Include='IISSetup' Description='IIS' Groups='{2}' />";
        }

        protected override XElement GenerateServerRoleXml()
        {
            return XmlHelper.CreateXElement(string.Format(BaseRoleString, Namespaces.CommonRole.XmlNamespace, RoleName, Groups));
        }


        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("IisSetupDeploy")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new IisSetupDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("IisSetupDeploy")]
        public void TestValidatesNonResponsibility()
        {
            var invalidRole = string.Format(
                @"<ServerRole xmlns='{0}' Name='TFL.ServerPrerequisite_INVALID' Description='CheckSqlIntegrationService' Include='CheckSqlIntegrationService' Groups='{1}'>{2}</ServerRole>",
                Namespaces.CommonRole.XmlNamespace, Groups, Body);

            var element = XmlHelper.CreateXElement(invalidRole);

            var factory = new IisSetupDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("IisSetupDeploy")]
        public void TestReadsCommonRole()
        {
            var factory = new IisSetupDeployFactory("default");

            //Body = CommonXml;
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var baseRole = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(baseRole);

            var deploy = baseRole as IisSetupDeploy;
            Assert.IsNotNull(deploy);
            Assert.IsTrue(deploy.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));

            //Assert.IsFalse(string.IsNullOrWhiteSpace(webServicePostDeploy.WebServicePath));
            Assert.IsFalse(string.IsNullOrWhiteSpace(deploy.Configuration));
            Assert.IsFalse(string.IsNullOrWhiteSpace(deploy.Description));
            Assert.IsFalse(string.IsNullOrWhiteSpace(deploy.Include));
            Assert.IsFalse(string.IsNullOrWhiteSpace(deploy.Name));
            Assert.IsFalse(string.IsNullOrWhiteSpace(deploy.RoleType));

            Assert.IsNotNull(deploy.Groups);
            Assert.IsTrue(deploy.Groups.Count > 0);
        }
    }
}
