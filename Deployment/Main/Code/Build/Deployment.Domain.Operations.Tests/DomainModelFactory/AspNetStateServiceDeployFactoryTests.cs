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
    public class AspNetStateServiceDeployFactoryTests : DomainOperationsTestBase
    {
        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.StateServiceSetup";
            Body = "<CreateFolder></CreateFolder>";
            Groups = "GroupTest";
            BaseRoleString = @"<ServerRole xmlns='{0}' Name='{1}' Description='Test Description' Include='State.Service.Setup' Groups='{2}'>{3}</ServerRole>";
        }

        protected override XElement GenerateServerRoleXml()
        {
            return XmlHelper.CreateXElement(string.Format(BaseRoleString, Namespaces.CommonRole.XmlNamespace, RoleName, Groups, Body));
        }

        private const string CommonXml = @"<CreateFolder TargetPath='\D$\tfl\BaselineTemp' />";

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("AspNetStateServiceDeploy")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new AspNetStateServiceDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }


        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("AspNetStateServiceDeploy")]
        public void TestValidatesNonResponsibility()
        {
            var invalidRole = string.Format(
                @"<ServerRole xmlns='{0}' Name='INVALID' Description='Test Description' Include='State.Service.Setup' Groups='{1}'>{2}</ServerRole>",
                Namespaces.CommonRole.XmlNamespace, Groups, Body);

            var element = XmlHelper.CreateXElement(invalidRole);
            var factory = new AspNetStateServiceDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }


        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("AppFabricPostDeploy")]
        public void TestReadsCommonRole()
        {
            var factory = new AspNetStateServiceDeployFactory("default");

            Body = CommonXml;
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var baseRole = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(baseRole);

            var appFabricPostDeploy = baseRole as AspNetStateServiceDeploy;
            Assert.IsNotNull(appFabricPostDeploy);
            Assert.IsTrue(appFabricPostDeploy.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));

            Assert.IsFalse(string.IsNullOrWhiteSpace(appFabricPostDeploy.Name));
            Assert.IsFalse(string.IsNullOrWhiteSpace(appFabricPostDeploy.Include));
            Assert.IsFalse(string.IsNullOrWhiteSpace(appFabricPostDeploy.Description));
            Assert.IsFalse(string.IsNullOrWhiteSpace(appFabricPostDeploy.Configuration));
            Assert.IsFalse(string.IsNullOrWhiteSpace(appFabricPostDeploy.Include));
            Assert.IsFalse(string.IsNullOrWhiteSpace(appFabricPostDeploy.RoleType));
        }
    }
}
