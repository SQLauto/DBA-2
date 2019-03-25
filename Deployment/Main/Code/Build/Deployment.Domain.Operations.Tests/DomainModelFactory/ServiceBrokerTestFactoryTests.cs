using System;
using System.Xml.Linq;
using Deployment.Common;
using Deployment.Common.Xml;
using Deployment.Domain.Operations.DomainModelFactory;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests.DomainModelFactory
{
    [TestClass]
    public class ServiceBrokerTestFactoryTests : DomainOperationsTestBase
    {

        [TestInitialize]
        public void Setup()
        {
            BaseRoleString = "<CustomTests>" + CommonXml + "</CustomTests>";
        }

        protected override XElement GenerateServerRoleXml()
        {
            return XmlHelper.CreateXElement(BaseRoleString);
        }

        private string CommonXml => "    <ServiceBrokerTest Name='TestName' Groups ='PARE,Notifications'>" + Environment.NewLine +
                                    "         <Sql>" + Environment.NewLine +
                                    "              <DatabaseServer>TDC2FAEC04V03</DatabaseServer>" + Environment.NewLine +
                                    "              <DatabaseInstance>vins003</DatabaseInstance>" + Environment.NewLine +
                                    "              <TargetDatabase>Notification</TargetDatabase>" + Environment.NewLine +
                                    "              <SqlScript>" + Environment.NewLine +
                                    "              </SqlScript>" + Environment.NewLine +
                                    "         </Sql>" + Environment.NewLine +
                                    "    </ServiceBrokerTest>" + Environment.NewLine +
                                    "";


        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ServiceBrokerTest")]
        [Ignore, Description("TODO: IsResponsibleFor test for ServiceBrokerTestFactory")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new ServiceBrokerTestFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ServiceBrokerTest")]
        public void TestValidatesNonResponsibility()
        {
            var invalidRole =
                $@"<ServerRole xmlns='{
                    Namespaces.CommonRole.XmlNamespace
                }' Name='TFL.ServerPrerequisite_INVALID' Description='CheckSqlIntegrationService' Include='CheckSqlIntegrationService' Groups='{
                    Groups
                }'>{CommonXml}</ServerRole>";

            var element = XmlHelper.CreateXElement(invalidRole);

            var factory = new ServiceBrokerTestFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

    }
}
