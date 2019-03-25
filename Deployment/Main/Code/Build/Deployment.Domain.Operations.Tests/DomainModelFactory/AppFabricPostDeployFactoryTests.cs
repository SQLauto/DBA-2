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
    public class AppFabricPostDeployFactoryTests : DomainOperationsTestBase
    {
        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.PostDeploy";
            Body = "<AppFabricPostDeploy></AppFabricPostDeploy>";
            Groups = "GroupTest";
            BaseRoleString = @"<PostDeployRole xmlns='{0}' Name='{1}' Description='Start Integration AppFabric Cluster' Include='AppFabric.Integration.Start' Groups='{2}'>{3}</PostDeployRole>";
        }

        private const string CommonXml = @"<AppFabricPostDeploy PortNumber='22233' State='Up' Action='Fix' />";

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("AppFabricPostDeploy")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new AppFabricPostDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("AppFabricPostDeploy")]
        public void TestValidatesNonResponsibility()
        {
            var invalidRole =
                $@"<PostDeployRole xmlns='{
                    Namespaces.CommonRole.XmlNamespace
                }' Name='TFL.PostDeploy_INVALID' Description='Start Integration AppFabric Cluster' Include='AppFabric.Integration.Start' Groups='{
                    Groups
                }'>{Body}</PostDeployRole>";

            var element = XmlHelper.CreateXElement(invalidRole);

            var factory = new AppFabricPostDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("AppFabricPostDeploy")]
        public void TestReadsCommonRole()
        {
            var factory = new AppFabricPostDeployFactory("default");

            Body = CommonXml;
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var baseRole = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(baseRole);

            var appFabricPostDeploy = baseRole as AppFabricPostDeploy;
            Assert.IsNotNull(appFabricPostDeploy);
            Assert.IsTrue(appFabricPostDeploy.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));

            Assert.IsFalse(string.IsNullOrWhiteSpace(appFabricPostDeploy.Name));
            Assert.IsFalse(string.IsNullOrWhiteSpace(appFabricPostDeploy.Include));
            Assert.IsFalse(string.IsNullOrWhiteSpace(appFabricPostDeploy.Description));
            Assert.AreEqual(appFabricPostDeploy.PortNumber, 22233);
            Assert.AreEqual(appFabricPostDeploy.Action, WindowsServiceActionType.Fix);
        }

        protected override XElement GenerateServerRoleXml()
        {
            return XmlHelper.CreateXElement(string.Format(BaseRoleString, Namespaces.CommonRole.XmlNamespace, RoleName, Groups, Body));
        }
    }
}
