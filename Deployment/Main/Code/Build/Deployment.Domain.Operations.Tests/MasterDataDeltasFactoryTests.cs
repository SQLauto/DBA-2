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
    public class MasterDataDeltasFactoryTests : DomainOperationsTestBase
    {

        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.MasterDataDeltas";
            Body = "<CopyAssets></CopyAssets>";
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("MasterDataDeltas")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new MasterDataDeltasFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("MasterDataDeltas")]
        public void TestValidatesNonResponsibility()
        {
            RoleName = "Invalid";
            var element = GenerateServerRoleXml();

            var factory = new MasterDataDeltasFactory("default");
            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("MasterDataDeltas")]
        public void TestReadsCommonRole()
        {
            var factory = new MasterDataDeltasFactory("default");

            var element = XmlHelper.CreateXElement(
                $@"<ServerRole xmlns='{
                    Namespaces.CommonRole.XmlNamespace
                }' Name='TFL.MasterDataDeltas' Description='Copy MJT Files' Include='MasterData.MJTService.Assets.Last13Weeks' Groups='MasterData'><CopyAssets Source='Assets' Daykeys='13150,13284,13296,13396' Subsystem='mjtdata\ftp'><TestInfo VerificationWaitTimeMilliSeconds='60000'><Port>8731</Port><EndPoint>status</EndPoint></TestInfo></CopyAssets></ServerRole>");

            Assert.IsTrue(factory.IsResponsibleFor(element));

            var validationResult = new ValidationResult();
            var role = factory.DomainModelCreate(element, ref validationResult);
            var deltas = role as MasterDataDeltas;

            Assert.IsTrue(validationResult.Result);
            Assert.IsNotNull(deltas);
            Assert.IsFalse(string.IsNullOrWhiteSpace(deltas.Source));
            Assert.IsFalse(string.IsNullOrWhiteSpace(deltas.Name));
            Assert.IsFalse(string.IsNullOrWhiteSpace(deltas.Subsystem));
            Assert.IsFalse(string.IsNullOrWhiteSpace(deltas.Include));
            Assert.IsFalse(string.IsNullOrWhiteSpace(deltas.CopyAssetsTestInfo.EndPoint));
            Assert.IsFalse(string.IsNullOrWhiteSpace(deltas.Description));
            Assert.IsTrue(deltas.DayKeys.Count > 0);
            Assert.IsTrue(deltas.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));
        }
    }
}