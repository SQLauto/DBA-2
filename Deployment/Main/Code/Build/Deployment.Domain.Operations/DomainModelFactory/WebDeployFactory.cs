using System;
using System.Collections.Generic;
using System.Xml.Linq;
using System.Xml.XPath;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class WebDeployFactory : BaseRoleFactory<WebDeploy>
    {
        public WebDeployFactory(string defaultConfig) : base(defaultConfig, new [] { "config:ServerRole[@Name='TFL.WebDeploy']", "role:ServerRole[@Name='TFL.WebDeploy']" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode,
            ref ValidationResult validationResult)
        {
            var retVal = new WebDeploy(DefaultConfig);

            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                var child = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "WebDeploy");

                if (child == null)
                {
                    validationResult.AddError("WebDeploy element was not found.");
                    return null;
                }

                ParseElementAttribute(child, "RegistryKey", () => retVal.RegistryKey, ref validationResult, ValidationAction.NotNullOrEmpty("WebDeploy - RegistryKey"));
                ParseElementAttribute(child, "AssemblyToVersionFrom", () => retVal.AssemblyToVersionFrom, ref validationResult, ValidationAction.NotNullOrEmpty("WebDeploy - AssemblyToVersionFrom"));

                ProcessAppPool(child, retVal, ref validationResult);
                ProcessSite(child, retVal.Site, ref validationResult);
                retVal.Package = ProcessPackage(child, ref validationResult);
                retVal.TestInfo = ProcessTestInfo(child, ref validationResult);
                retVal.ConfigurationEncryption.AddRange(ProcessConfigEncryption(child, ref validationResult));

                ValidateDomainObject(retVal, ref validationResult, true);
            }
            catch (Exception ex)
            {
                validationResult.AddException(ex);
                return null;
            }

            return validationResult.Result ? retVal : null;
        }

        public override bool ValidateDomainObject(WebDeploy domainObject, ref ValidationResult validationResult,
            bool suppressStandardParseValidations = false)
        {
            return validationResult.Result;
        }


        private void ProcessAppPool(XElement rootNode, WebDeploy role, ref ValidationResult validationResult)
        {
            var childNode = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "AppPool");

            if (childNode == null)
            {
                validationResult.AddError("WebDeploy element does not have an AppPool element.");
                return;
            }

            var appPool = new AppPool();
            role.AppPool = appPool;

            ParseElementValue(childNode, "Name", Namespaces.CommonRole.XmlNamespace, () => appPool.Name, ref validationResult, ValidationAction.NotNullOrEmpty("WebDeploy - Name"));
            ParseElementValue(childNode, "ServiceAccount", Namespaces.CommonRole.XmlNamespace, () => appPool.ServiceAccount, ref validationResult, ValidationAction.NotNullOrEmpty("WebDeploy - ServiceAccount"));
            ParseElementValue(childNode, "IdleTimeout", Namespaces.CommonRole.XmlNamespace, () => appPool.IdleTimeout, ref validationResult, ValidationAction.EqualToOrGreaterThanZero("WebDeploy - TestInfo IdleTimeout"));
            ParseElementValue(childNode, "RecycleLogEvent", Namespaces.CommonRole.XmlNamespace, appPool.RecycleLogEvents, ref validationResult);
        }

        private void ProcessSite(XElement rootNode, WebSite site, ref ValidationResult validationResult)
        {
            var childNode = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "Site");

            if (childNode == null)
            {
                validationResult.AddError("WebDeploy element does not have a Site element.");
                return;
            }

            ParseElementValue(childNode, "Name", Namespaces.CommonRole.XmlNamespace, () => site.Name, ref validationResult, ValidationAction.NotNullOrEmpty("WebDeploy - Site Name"));
            ParseElementValue(childNode, "Port", Namespaces.CommonRole.XmlNamespace, () => site.Port, ref validationResult, ValidationAction.GreaterThanZero("WebDeploy - Site Port"));
            ParseElementValue(childNode, "PhysicalPath", Namespaces.CommonRole.XmlNamespace, () => site.PhysicalPath, ref validationResult, ValidationAction.NotNullOrEmpty("WebDeploy - Site PhysicalPath"));
            ParseElementValue(childNode, "DirectoryBrowsingEnabled", Namespaces.CommonRole.XmlNamespace, () => site.DirectoryBrowsingEnabled, ref validationResult);

            site.AuthenticationModes = new List<WebAuthenticationMode>();
            var authNodes = childNode.XPathSelectElements(string.Format("{0}:Authentication", Namespaces.CommonRole.Prefix), Namespaces.NamespaceManager);
            ParseElementValue(authNodes, site.AuthenticationModes, ref validationResult);

            var subNode = childNode.Element(Namespaces.CommonRole.XmlNamespace + "VirtualDirectory");

            if (subNode != null)
            {
                var virtualDirectory = new VirtualDirectory();
                ParseElementValue(subNode, "Name", Namespaces.CommonRole.XmlNamespace, () => virtualDirectory.Name, ref validationResult, ValidationAction.NotNullOrEmpty("WebDeploy - VirtualDirectory Name"));
                ParseElementValue(subNode, "PhysicalPath", Namespaces.CommonRole.XmlNamespace, () => virtualDirectory.PhysicalPath, ref validationResult, ValidationAction.NotNullOrEmpty("WebDeploy - VirtualDirectory PhysicalPath"));
            }

            subNode = childNode.Element(Namespaces.CommonRole.XmlNamespace + "Application");

            if (subNode != null)
            {
                var webApp = new WebApplication();
                ParseElementValue(subNode, "Name", Namespaces.CommonRole.XmlNamespace, () => webApp.Name, ref validationResult, ValidationAction.NotNullOrEmpty("WebDeploy - Application Name"));
                ParseElementValue(subNode, "PhysicalPath", Namespaces.CommonRole.XmlNamespace, () => webApp.PhysicalPath, ref validationResult, ValidationAction.NotNullOrEmpty("WebDeploy - Application PhysicalPath"));
            }
        }

        private Package ProcessPackage(XElement rootNode, ref ValidationResult validationResult)
        {
            var childNode = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "Package");

            if (childNode == null)
            {
                return null;
            }

            var package = new Package();
            ParseElementValue(childNode, "Name", Namespaces.CommonRole.XmlNamespace, () => package.Name, ref validationResult, ValidationAction.NotNullOrEmpty("WebDeploy - Package Name cannot be null or empty."));
            return package;
        }

        private WebTestInfo ProcessTestInfo(XElement rootNode, ref ValidationResult validationResult)
        {
            var childNode = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "TestInfo");

            if (childNode == null)
            {
                return null;
            }

            var webTestInfo = new WebTestInfo();
            var items = childNode.Elements(Namespaces.CommonRole.XmlNamespace + "EndPoint");

            foreach (var xElement in items)
            {
                var endPoint = new WebTestEndPoint { Value = xElement.Value };
                ParseElementAttribute(xElement, "TestIdentity", () => endPoint.TestIdentity, ref validationResult, ValidationAction.NotNullOrEmpty("WebDeploy - TestInfo TestIdentity"));
                ParseElementAttribute(xElement, "ContentType", () => endPoint.ContentType, ref validationResult, ValidationAction.NotNullOrEmpty("WebDeploy - ContentType TestIdentity"));
                ParseElementAttribute(xElement, "Authentication", () => endPoint.Authentication, ref validationResult);
                webTestInfo.EndPoints.Add(endPoint);
            }

            return webTestInfo;
        }

        private IEnumerable<WebConfigurationEncryption> ProcessConfigEncryption(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new List<WebConfigurationEncryption>();

            var childNode = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "Encryption");

            if (childNode != null)
            {
                var items = childNode.Elements(Namespaces.CommonRole.XmlNamespace + "Encrypt");

                foreach (var xElement in items)
                {
                    var webConfigEnc = new WebConfigurationEncryption();
                    ParseElementAttribute(xElement, "Section", () => webConfigEnc.Section, ref validationResult, ValidationAction.NotNullOrEmpty("WebDeploy - Encryption Section"));
                    retVal.Add(webConfigEnc);
                }
            }

            return retVal;
        }
    }
}