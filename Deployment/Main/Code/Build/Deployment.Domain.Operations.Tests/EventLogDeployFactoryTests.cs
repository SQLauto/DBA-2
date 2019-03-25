using System;
using System.Linq;
using Deployment.Common;
using Deployment.Common.Xml;
using Deployment.Domain.Operations.DomainModelFactory;
using Deployment.Domain.Roles;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class EventLogDeployFactoryTests
    {
        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("EventLogDeploy")]
        public void TestValidatesResponsibility()
        {
            var element = XmlHelper.CreateXElement(GenerateXmlString(body: "<Testy />"));

            var factory = new EventLogDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("EventLogDeploy")]
        public void TestValidatesNonResponsibility()
        {
            var element = XmlHelper.CreateXElement(GenerateXmlString("TFL.Testy", body: "<Testy />"));

            var factory = new EventLogDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("EventLogDeploy")]
        public void TestValidatesLogName()
        {
            var element = XmlHelper.CreateXElement(string.Format(@"<ServerRole xmlns='{0}' Name='TFL.EventLogDeploy' Include='Simple.Event.Logs' Description='SimpleEventLogs' Groups='Win'><EventLogDeploy EventLogName=''><Sources><Source Name='AzureMobileUploader' /></Sources></EventLogDeploy></ServerRole>", Namespaces.CommonRole.XmlNamespace));

            var factory = new EventLogDeployFactory("default");

            var validationResult = new ValidationResult();
            var evenLogDeploy = factory.DomainModelCreate(element, ref validationResult);

            Assert.IsFalse(validationResult.Result);
            Assert.IsNull(evenLogDeploy);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("EventLogDeploy")]
        public void TestSourceNameNotNull()
        {
            var factory = new EventLogDeployFactory("default");

            var element = XmlHelper.CreateXElement(string.Format(@"<ServerRole xmlns='{0}' Name='TFL.EventLogDeploy' Include='Simple.Event.Logs' Description='SimpleEventLogs' Groups='Win'><EventLogDeploy EventLogName='FTP'><Sources><Source Name='' /></Sources></EventLogDeploy></ServerRole>", Namespaces.CommonRole.XmlNamespace));

            var validationResult = new ValidationResult();
            var evenLogDeploy = factory.DomainModelCreate(element, ref validationResult);

            Assert.IsFalse(validationResult.Result);
            Assert.IsNull(evenLogDeploy);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("EventLogDeploy")]
        public void TestReadsCommonRole()
        {
            var factory = new EventLogDeployFactory("default");

            var element = XmlHelper.CreateXElement(string.Format(@"<ServerRole xmlns='{0}' Name='TFL.EventLogDeploy' Include='Simple.Event.Logs' Description='SimpleEventLogs' Groups='Win'><EventLogDeploy EventLogName='FTP'><Sources><Source Name='AzureMobileUploader' /></Sources></EventLogDeploy></ServerRole>", Namespaces.CommonRole.XmlNamespace));

            var validationResult = new ValidationResult();
            var role = factory.DomainModelCreate(element, ref validationResult);
            var evenLogDeploy = role as EventLogDeploy;

            Assert.IsTrue(validationResult.Result);
            Assert.IsNotNull(evenLogDeploy);
            Assert.IsFalse(string.IsNullOrWhiteSpace(evenLogDeploy.EventLogName));
            Assert.IsTrue(evenLogDeploy.Sources.Count > 0);
            Assert.IsFalse(evenLogDeploy.Sources.Any(string.IsNullOrWhiteSpace));
            Assert.IsFalse(string.IsNullOrWhiteSpace(evenLogDeploy.Name));
            Assert.IsFalse(string.IsNullOrWhiteSpace(evenLogDeploy.Include));
            Assert.IsFalse(string.IsNullOrWhiteSpace(evenLogDeploy.Description));
            Assert.IsTrue(evenLogDeploy.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));
            Assert.IsTrue(evenLogDeploy.Action == EventLogAction.Install);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("EventLogDeploy")]
        public void TestOverridesDefatultConfig()
        {
            var factory = new EventLogDeployFactory("default");

            var element = XmlHelper.CreateXElement(string.Format(@"<ServerRole xmlns='{0}' Name='TFL.EventLogDeploy' Include='Simple.Event.Logs' Description='SimpleEventLogs' Config='Test1' Groups='Win'><EventLogDeploy EventLogName='FTP'><Sources><Source Name='AzureMobileUploader' /></Sources></EventLogDeploy></ServerRole>", Namespaces.CommonRole.XmlNamespace));

            var validationResult = new ValidationResult();
            var evenLogDeploy = factory.DomainModelCreate(element, ref validationResult);

            Assert.IsTrue(validationResult.Result);
            Assert.IsNotNull(evenLogDeploy);
            Assert.IsFalse(string.IsNullOrWhiteSpace(evenLogDeploy.Configuration));
            Assert.IsTrue(evenLogDeploy.Configuration.Equals("Test1", StringComparison.InvariantCultureIgnoreCase));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("EventLogDeploy")]
        public void TestGeneratesGroupsList()
        {
            var factory = new EventLogDeployFactory("default");

            var element = XmlHelper.CreateXElement(string.Format(@"<ServerRole xmlns='{0}' Name='TFL.EventLogDeploy' Include='Simple.Event.Logs' Description='SimpleEventLogs' Groups='Group1, Group2'><EventLogDeploy EventLogName='FTP'><Sources><Source Name='AzureMobileUploader' /></Sources></EventLogDeploy></ServerRole>", Namespaces.CommonRole.XmlNamespace));

            var validationResult = new ValidationResult();
            var evenLogDeploy = factory.DomainModelCreate(element, ref validationResult);

            Assert.IsTrue(validationResult.Result);
            Assert.IsNotNull(evenLogDeploy);
            Assert.IsTrue(evenLogDeploy.Groups.Count == 2);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("EventLogDeploy")]
        public void TestReadsValidEnumValue()
        {
            var factory = new EventLogDeployFactory("default");

            var element = XmlHelper.CreateXElement(string.Format(@"<ServerRole xmlns='{0}' Name='TFL.EventLogDeploy' Include='Simple.Event.Logs' Description='SimpleEventLogs' Groups='Group2'><EventLogDeploy EventLogName='FTP' Action='Uninstall'><Sources><Source Name='AzureMobileUploader' /></Sources></EventLogDeploy></ServerRole>", Namespaces.CommonRole.XmlNamespace));

            var validationResult = new ValidationResult();
            var role = factory.DomainModelCreate(element, ref validationResult);
            var evenLogDeploy = role as EventLogDeploy;

            Assert.IsTrue(validationResult.Result);
            Assert.IsNotNull(evenLogDeploy);
            Assert.IsTrue(evenLogDeploy.Action == EventLogAction.Uninstall);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("EventLogDeploy")]
        public void TestHandlesInvalidEnumValue()
        {
            var factory = new EventLogDeployFactory("default");

            var element = XmlHelper.CreateXElement(GenerateXmlString(body: "<EventLogDeploy EventLogName='FTP' Action='Cheese'><Sources><Source Name='AzureMobileUploader' /></Sources></EventLogDeploy>"));

            var validationResult = new ValidationResult();
            var evenLogDeploy = factory.DomainModelCreate(element, ref validationResult);

            Assert.IsFalse(validationResult.Result);
            Assert.IsNull(evenLogDeploy);
        }

        private string GenerateXmlString(string name = "TFL.EventLogDeploy", string groups = "Group1", string body = "")
        {
            var baseString =
                @"<ServerRole xmlns='{3}' Name='{0}' Include='IncludeValue' Description='BasicDescription' Groups='{1}'>{2}</ServerRole>";

            return string.Format(baseString, name, groups, body, Namespaces.CommonRole.XmlNamespace);
        }
    }
}