using System;
using Deployment.Common;
using Deployment.Domain.Operations.DomainModelFactory;
using Deployment.Domain.Roles;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class ServiceDeployFactoryTests : DomainOperationsTestBase
    {
        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.ServiceDeploy";
            Body = "<ServiceDeploy Name='TestName'>{0}</ServiceDeploy>";
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ServiceDeploy")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new ServiceDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ServiceDeploy")]
        public void TestValidatesNonResponsibility()
        {
            RoleName = "Invalid";
            var element = GenerateServerRoleXml();

            var factory = new ServiceDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ServiceDeploy")]
        public void TestValidatesUpgradeCodeOrProductCodeMustBeSpecified()
        {
            var factory = new ServiceDeployFactory("default");
            var serviceDeploy = new ServiceDeploy("default");
            var validationResult = new ValidationResult();

            bool result = factory.ValidateDomainObject(serviceDeploy, ref validationResult, false);
            Assert.IsFalse(result);
            Assert.IsFalse(validationResult.Result);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ServiceDeploy")]
        public void TestSetsDefatultConfig()
        {
            var factory = new ServiceDeployFactory("default");

            Body = string.Format(Body, BasicXml);
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsFalse(string.IsNullOrWhiteSpace(model.Configuration));
            Assert.IsTrue(model.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));

            Assert.IsInstanceOfType(model, typeof(ServiceDeploy));

            var serviceDeploy = (ServiceDeploy)model;
            Assert.IsTrue(serviceDeploy.MsiDeploy.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ServiceDeploy")]
        public void TestOverridesDefatultConfig()
        {
            var factory = new ServiceDeployFactory("default");
            Config = "Config='Test1'";

            Body = string.Format(Body, BasicXml);
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsFalse(string.IsNullOrWhiteSpace(model.Configuration));
            Assert.IsTrue(model.Configuration.Equals("Test1", StringComparison.InvariantCultureIgnoreCase));

            Assert.IsInstanceOfType(model, typeof(ServiceDeploy));

            var serviceDeploy = (ServiceDeploy)model;
            Assert.IsTrue(serviceDeploy.MsiDeploy.Configuration.Equals("Test1", StringComparison.InvariantCultureIgnoreCase));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ServiceDeploy")]
        public void TestOverridesInstallAction()
        {
            var factory = new ServiceDeployFactory("default");

            Body = string.Format(Body, BasicXml);
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsFalse(string.IsNullOrWhiteSpace(model.Configuration));

            var temp = (ServiceDeploy) model;

            Assert.IsTrue(temp.MsiDeploy.Action == MsiAction.Install, "Action should be Install, but was Uninstall");

            BaseRoleString =
                @"<ServerRole xmlns='{4}' Name='{0}' Include='Include' Description='Description' Groups='{1}' {2} Action='Uninstall'>{3}</ServerRole>";

            Body = string.Format(Body, BasicXml);
            var parent = GenerateServerRoleXml();

            var role = factory.ApplyOverrides(model, parent, ref validationResult) as ServiceDeploy;

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(role);

            Assert.IsTrue(role.MsiDeploy.Action == MsiAction.Uninstall, "Action should be Uninstall, but was Install");
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ServiceDeploy")]
        public void TestActionSetToUninstall()
        {
            var factory = new ServiceDeployFactory("default");

            Body = $"<ServiceDeploy Name='TestName' Action='Uninstall'>{BasicXml}</ServiceDeploy>";
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsInstanceOfType(model, typeof(ServiceDeploy));
            var deployRole = (ServiceDeploy)model;
            Assert.IsTrue(deployRole.Action == MsiAction.Uninstall);
            Assert.IsTrue(deployRole.MsiDeploy.Action == MsiAction.Uninstall);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ServiceDeploy")]
        public void TestDefaultStartUpTypeSetToAutomatic()
        {
            var factory = new ServiceDeployFactory("default");

            Body = $"<ServiceDeploy Name='TestName'>{BasicXml}</ServiceDeploy>";
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsInstanceOfType(model, typeof(ServiceDeploy));
            var deployRole = (ServiceDeploy)model;
            Assert.IsTrue(deployRole.Services[0].StartupType == WindowsServiceStartupType.Automatic, $"StartUpType should be Automatic, but was {deployRole.Services[0].StartupType}");
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ServiceDeploy")]
        public void TestOverridesStartUpType()
        {
            var factory = new ServiceDeployFactory("default");

            Body = string.Format(Body, BasicXml);
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsFalse(string.IsNullOrWhiteSpace(model.Configuration));

            var temp = (ServiceDeploy)model;

            Assert.IsTrue(temp.Services[0].StartupType == WindowsServiceStartupType.Automatic, $"StartUpType should be Automatic, but was {temp.Services[0].StartupType}");

            BaseRoleString =
                @"<ServerRole xmlns='{4}' Name='{0}' Include='Include' Description='Description' Groups='{1}' {2} StartUpType='Disabled'>{3}</ServerRole>";

            Body = string.Format(Body, BasicXml);
            var parent = GenerateServerRoleXml();

            var role = factory.ApplyOverrides(model, parent, ref validationResult) as ServiceDeploy;

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(role);

            Assert.IsTrue(role.Services[0].StartupType == WindowsServiceStartupType.Disabled, $"StartUpType should be Disabled, but was {role.Services[0].StartupType}");
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ServiceDeploy")]
        public void TestReadsClusterInfo()
        {
            var factory = new ServiceDeployFactory("default");

            Body = string.Format(Body, ClusterInfoXml);
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsFalse(string.IsNullOrWhiteSpace(model.Configuration));

            var temp = (ServiceDeploy)model;

            Assert.AreEqual(1, temp.Services.Count);
            Assert.IsNotNull(temp.Services[0].ClusterInfo);
            Assert.AreEqual("TestResource", temp.Services[0].ClusterInfo.ResourceName);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ServiceDeploy")]
        public void TestReadsTestInfo()
        {
            var factory = new ServiceDeployFactory("default");

            Body = string.Format(Body, TestnInfoXml);
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsFalse(string.IsNullOrWhiteSpace(model.Configuration));

            var temp = (ServiceDeploy)model;

            Assert.AreEqual(1, temp.Services.Count);
            Assert.IsTrue(temp.DisableTests);
            Assert.AreEqual(1000, temp.VerificationWaitTime);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ServiceDeploy")]
        public void TestHasRenameValue()
        {
            var factory = new ServiceDeployFactory("default");

            Body = string.Format(Body, RenameXml);
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsFalse(string.IsNullOrWhiteSpace(model.Configuration));

            var temp = (ServiceDeploy)model;

            Assert.AreEqual(1, temp.Services.Count);
            Assert.AreEqual("NewName", temp.Services[0].Name);
            Assert.AreEqual("OldName", temp.Services[0].CurrentName);
        }

        private const string BasicXml = @"<MSI>
    <name>SomeName</name>
    <UpgradeCode>7380ACDE-ADDF-4D00-881B-C4134CBEF904</UpgradeCode>
    <parameters>
        <parameter name='Test' value='Test' />
        <parameter name='INSTALLLOCATION' value='D:\TestPath' />
    </parameters>
 </MSI>
<Services>
    <Service StartUpType=""Automatic"">
        <Name>Service</Name>
        <Credentials>Creds</Credentials>
    </Service>
</Services>
<Configs>
          <config name=""Tfl.FileTransferManagerService.exe.config"" target=""\tfl\FTM\FileTransferManager.Service"" />
        </Configs>";

        private const string RenameXml = @"<MSI>
    <name>SomeName</name>
    <UpgradeCode>7380ACDE-ADDF-4D00-881B-C4134CBEF904</UpgradeCode>
    <parameters>
        <parameter name='Test' value='Test' />
        <parameter name='INSTALLLOCATION' value='D:\TestPath' />
    </parameters>
 </MSI>
<Services>
    <Service StartUpType=""Automatic"">
        <Name>NewName</Name>
        <CurrentName>OldName</CurrentName>
        <Credentials>Creds</Credentials>
    </Service>
</Services>
<Configs>
          <config name=""Tfl.FileTransferManagerService.exe.config"" target=""\tfl\FTM\FileTransferManager.Service"" />
        </Configs>";

        private const string TestnInfoXml = @"<MSI>
    <name>SomeName</name>
    <UpgradeCode>7380ACDE-ADDF-4D00-881B-C4134CBEF904</UpgradeCode>
    <parameters>
        <parameter name='Test' value='Test' />
        <parameter name='INSTALLLOCATION' value='D:\TestPath' />
    </parameters>
 </MSI>
<Services>
    <Service StartUpType=""Automatic"">
        <Name>Service</Name>
        <Credentials>Creds</Credentials>
    </Service>
</Services>
<Configs>
          <config name=""Tfl.FileTransferManagerService.exe.config"" target=""\tfl\FTM\FileTransferManager.Service"" />
        </Configs>
    <TestInfo DisableTests=""true"" VerificationWaitTimeMilliSeconds=""1000""/>";

        private const string ClusterInfoXml = @"<MSI>
    <name>SomeName</name>
    <UpgradeCode>7380ACDE-ADDF-4D00-881B-C4134CBEF904</UpgradeCode>
    <parameters>
        <parameter name='Test' value='Test' />
        <parameter name='INSTALLLOCATION' value='D:\TestPath' />
    </parameters>
 </MSI>
<Services>
    <Service StartUpType=""Automatic"">
        <Name>Service</Name>
        <Credentials>Creds</Credentials>
        <ClusterInfo>
            <ResourceName>TestResource</ResourceName>
        </ClusterInfo>
    </Service>
</Services>
<Configs>
          <config name=""Tfl.FileTransferManagerService.exe.config"" target=""\tfl\FTM\FileTransferManager.Service"" />
        </Configs>";
    }
}