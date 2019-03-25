using Deployment.Common.Xml;
using Deployment.Domain.Operations.Services;
using Microsoft.VisualStudio.TestTools.UnitTesting;

using System.IO;
using System.Xml;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class DeploymentManifestFactoryTests
    {
        private string _deploymentManifestXml;
        private RootPathBuilder _pathBuilder;

        [TestInitialize]
        public void Setup()
        {
            _pathBuilder = new RootPathBuilder(TestContext.DeploymentDirectory) { IsLocalDebugMode = true };
            _pathBuilder.PackageDirectory = Path.Combine(_pathBuilder.RootDirectory, "Packages");

            if (!Directory.Exists(_pathBuilder.PackageDirectory))
                Directory.CreateDirectory(_pathBuilder.PackageDirectory);

            _deploymentManifestXml =
                @"<?xml version='1.0' encoding='UTF-8'?>
                    <Deployments>
                      <Deployment Index='0' IsDatabaseDeployment='true'>
                        <Package Name='Deployment.Baseline.PAK_160805.1_Config_DB.zip' Config='Baseline.DB.config.xml' Environment='Baseline' Groups='' Servers='' Partition='' />
                        <DeploymentServer Name='TS-DB1' ExternalIP='' DeploymentTempPath='' />
                        <DeploymentAccount Name='FAELAB\TFSBuild' Password='vIgxmg6jvCDA1nUHWi8Xzw==' />
                      </Deployment>
                      <Deployment Index='1'>
                        <Package Name='Deployment.Baseline.PAK_160805.1_Config_WebApps.zip' Config='Baseline.Apps.Config.xml' Environment='Baseline' Groups='Web' Servers='' Partition='' />
                        <DeploymentServer Name='TS-DB1' ExternalIP='' DeploymentTempPath='' />
                        <DeploymentAccount Name='FAELAB\TFSBuild' Password='vIgxmg6jvCDA1nUHWi8Xzw==' />
                      </Deployment>
                      <Deployment Index='2'>
                        <Package Name='Deployment.Baseline.PAK_160805.1_Config_WinApps.zip' Config='Baseline.Apps.Config.xml' Environment='Baseline' Groups='Win' Servers='' Partition='' />
                        <DeploymentServer Name='TS-DB1' ExternalIP='' DeploymentTempPath='' />
                        <DeploymentAccount Name='FAELAB\TFSBuild' Password='vIgxmg6jvCDA1nUHWi8Xzw==' />
                      </Deployment>
                    </Deployments>";

            XmlDocument doc = new XmlDocument();
            doc.LoadXml(_deploymentManifestXml);
            doc.Save(Path.Combine(_pathBuilder.PackageDirectory, "PackageManifest.xml"));
        }

        public TestContext TestContext { get; set; }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("DeploymentManifest")]
        public void TestReadsXml()
        {
            var factory = new DeploymentManifestService(_pathBuilder, new XmlParserService(), null);
            var manifest = factory.ParseManifestXml();
            Assert.IsNotNull(manifest);
            Assert.AreEqual(3, manifest.Deployments.Count);
        }
    }
}