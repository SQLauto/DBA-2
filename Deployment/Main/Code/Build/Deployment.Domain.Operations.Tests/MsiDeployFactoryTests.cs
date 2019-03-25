using System.Linq;
using Deployment.Common;
using Deployment.Common.Xml;
using Deployment.Domain.Operations.DomainModelFactory;
using Deployment.Domain.Roles;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class MsiDeployFactoryTests : DomainOperationsTestBase
    {

        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.MsiDeploy";
            Body = "<MsiDeploy></MsiDeploy>";
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("MSIDeploy")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new MsiDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("MSIDeploy")]
        public void TestValidatesNonResponsibility()
        {
            RoleName = "Invalid";
            var element = GenerateServerRoleXml();

            var factory = new MsiDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("MSIDeploy")]
        public void TestReadsCommonRole()
        {
            var factory = new MsiDeployFactory("default");

            var element = XmlHelper.CreateXElement(string.Format(@"<ServerRole xmlns='{0}' Name='TFL.MsiDeploy' Include='Simple.Console.AppX.Uninstall' Description='SimpleConsoleAppX Uninstall' Config='BaselineX' Groups='Win'><MsiDeploy Name='SimpleConsoleAppX Installer' Action='Uninstall'><MSI><name>WixSimpleConsoleAppInstaller.msi</name><UpgradeCode>F8B6DDF7-20B0-4EAA-A8CC-88265E3ECBCE</UpgradeCode><parameters><parameter name='INSTALLLOCATION' value='d:\tfl\baseline\SimpleConsoleApp' /></parameters></MSI><Configs><config name='SimpleConsoleApp.exe.config' target='\tfl\baseline\SimpleConsoleApp' /></Configs></MsiDeploy></ServerRole>", Namespaces.CommonRole.XmlNamespace));
            Assert.IsTrue(factory.IsResponsibleFor(element));

            var validationResult = new ValidationResult();
            var role = factory.DomainModelCreate(element, ref validationResult);
            var msiDeploy = role as MsiDeploy;

            Assert.IsTrue(validationResult.Result);
            Assert.IsNotNull(msiDeploy);
            Assert.IsNotNull(msiDeploy.Msi);
            Assert.IsTrue(msiDeploy.Configs.Any());
            Assert.IsTrue(msiDeploy.Parameters.Any());
            Assert.IsFalse(string.IsNullOrWhiteSpace(msiDeploy.Configuration));
            Assert.IsFalse(string.IsNullOrWhiteSpace(msiDeploy.Description));
            Assert.IsFalse(string.IsNullOrWhiteSpace(msiDeploy.Include));
            Assert.IsFalse(string.IsNullOrWhiteSpace(msiDeploy.Name));
            Assert.IsFalse(string.IsNullOrWhiteSpace(msiDeploy.Msi.Name));
            Assert.IsNotNull(msiDeploy.Msi.UpgradeCode);
            Assert.IsFalse(string.IsNullOrWhiteSpace(msiDeploy.Configuration));
            Assert.IsFalse(string.IsNullOrWhiteSpace(msiDeploy.Configuration));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("MSIDeploy")]
        public void TestValidatesUpgradeCodeOrProductCodeMustBeSpecified()
        {
            var factory = new MsiDeployFactory("default");
            var msiDeploy = new MsiDeploy();
            var validationResult = new ValidationResult();

            bool result = factory.ValidateDomainObject(msiDeploy, ref validationResult, false);
            Assert.IsFalse(result);
            Assert.IsFalse(validationResult.Result);
        }
    }
}