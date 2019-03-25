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
    public class WindowsServicePostDeployFactoryTests : DomainOperationsTestBase
    {
        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.PostDeploy";
            Body = "<WindowsServicePostDeploy></WindowsServicePostDeploy>";
            Groups = "GroupTest";
            BaseRoleString = @"<PostDeployRole xmlns='{0}' Name='{1}' Description='Start Integration AppFabric Cluster' Include='AppFabric.Integration.Start' Groups='{2}'>{3}</PostDeployRole>";
        }

        protected override XElement GenerateServerRoleXml()
        {
            return XmlHelper.CreateXElement(string.Format(BaseRoleString, Namespaces.CommonRole.XmlNamespace, RoleName, Groups, Body));
        }

        private const string CommonXml = @"<WindowsServicePostDeploy ServiceName='TapImporterService.exe' State='Running' Action='Fix' />";

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("WindowsServicePostDeploy")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new WindowsServicePostDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("WindowsServicePostDeploy")]
        public void TestValidatesNonResponsibility()
        {
            var invalidRole = string.Format(
                @"<PostDeployRole xmlns='{0}' Name='TFL.PostDeploy_INVALID' Description='Start Integration AppFabric Cluster' Include='AppFabric.Integration.Start' Groups='{1}'>{2}</PostDeployRole>",
                Namespaces.CommonRole.XmlNamespace, Groups, Body);

            var element = XmlHelper.CreateXElement(invalidRole);

            var factory = new WindowsServicePostDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("WindowsServicePostDeploy")]
        public void TestReadsCommonRole()
        {
            var factory = new WindowsServicePostDeployFactory("default");

            Body = CommonXml;
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var baseRole = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(baseRole);

            var windowsServicePostDeploy = baseRole as WindowsServicePostDeploy;
            Assert.IsNotNull(windowsServicePostDeploy);
            Assert.IsTrue(windowsServicePostDeploy.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));

            Assert.IsFalse(string.IsNullOrWhiteSpace(windowsServicePostDeploy.Name));
            Assert.IsFalse(string.IsNullOrWhiteSpace(windowsServicePostDeploy.ServiceName));
            Assert.IsFalse(string.IsNullOrWhiteSpace(windowsServicePostDeploy.Include));
            Assert.IsFalse(string.IsNullOrWhiteSpace(windowsServicePostDeploy.Description));

            Assert.AreEqual(windowsServicePostDeploy.State, WindowsServiceStateType.Running);
            Assert.AreEqual(windowsServicePostDeploy.Action, WindowsServiceActionType.Fix);
        }
    }
}
