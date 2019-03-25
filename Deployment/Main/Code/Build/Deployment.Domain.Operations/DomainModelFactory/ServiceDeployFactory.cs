using System;
using System.Collections.Generic;
using System.Xml.Linq;
using System.Xml.XPath;
using Deployment.Common;
using Deployment.Common.Helpers;
using Deployment.Common.Xml;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class ServiceDeployFactory : BaseRoleFactory<ServiceDeploy>
    {
        public ServiceDeployFactory(string defaultConfig) : base(defaultConfig, new[] { "role:ServerRole[@Name='TFL.ServiceDeploy']", "config:ServerRole[@Name='TFL.ServiceDeploy']" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new ServiceDeploy(DefaultConfig);

            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                var child = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "ServiceDeploy");

                if (child == null)
                {
                    validationResult.AddError("No ServiceDeploy element was found.");
                    return null;
                }

                ProcessMsi(child, retVal.MsiDeploy, ref validationResult);
                ProcessServices(child, retVal.Services, ref validationResult);

                var xpathExpression = string.Format("{0}:Configs/{0}:config", Namespaces.CommonRole.Prefix);

                foreach (var config in child.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager))
                {
                    var msiConfig = new MsiConfig();
                    ParseElementAttribute(config, "name", () => msiConfig.Name, ref validationResult, ValidationAction.NotNullOrEmpty("ServiceDeployment - name"));
                    ParseElementAttribute(config, "target", () => msiConfig.Target, ref validationResult, ValidationAction.NotNullOrEmpty("DeploymentManifest - target"));

                    retVal.MsiDeploy.Configs.Add(msiConfig);
                }

                if (retVal.MsiDeploy.Configs.IsNullOrEmpty())
                {
                    var error = $"ServerRole '{retVal.Name ?? "UNSPECIFIED"}' ({retVal.Description ?? string.Empty}) does not specify any configs.";

                    validationResult.AddError(error);
                }

                ParseElementAttribute(child.Element(Namespaces.CommonRole.XmlNamespace + "TestInfo"), "DisableTests", () => retVal.DisableTests, ref validationResult);
                ParseElementAttribute(child.Element(Namespaces.CommonRole.XmlNamespace + "TestInfo"), "VerificationWaitTimeMilliSeconds", () => retVal.VerificationWaitTime, ref validationResult);

                ParseElementAttribute(child, "Action", () => retVal.Action, ref validationResult);

                retVal.MsiDeploy.Action = retVal.Action;
                retVal.MsiDeploy.Configuration = retVal.Configuration;
                retVal.MsiDeploy.Description = retVal.Description;

                retVal.MsiDeploy.Groups.Clear();
                retVal.MsiDeploy.Groups.AddRange(retVal.Groups);

                ValidateDomainObject(retVal, ref validationResult, true);
            }
            catch (Exception ex)
            {
                validationResult.AddException(ex);
                return null;
            }

            return validationResult.Result ? retVal : null;
        }

        public override bool ValidateDomainObject(ServiceDeploy domainObject, ref ValidationResult validationResult,
            bool suppressStandardParseValidations = false)
        {
            bool productCodeSpecified = domainObject.MsiDeploy.Msi.ProductCode != null &&
                                           domainObject.MsiDeploy.Msi.ProductCode != default(Guid);
            bool upgradeCodeSpecified = domainObject.MsiDeploy.Msi.UpgradeCode != null &&
                                           domainObject.MsiDeploy.Msi.UpgradeCode != default(Guid);

            if (!productCodeSpecified && !upgradeCodeSpecified)
            {
                validationResult.AddError(
                    $"ServerRole '{domainObject.Name ?? "UNSPECIFIED"}' ({domainObject.Description ?? string.Empty}) must have at least one of the following specified [id] (which is the product code) or [UpgradeCode] in the MSI block.");
            }

            return validationResult.Result;
        }

        public override IBaseRole ApplyOverrides(IBaseRole commonRole, XElement includedRole, ref ValidationResult validationResult)
        {
            var retVal =  (ServiceDeploy)base.ApplyOverrides(commonRole, includedRole, ref validationResult);

            var actionTuple = includedRole.TryReadAttribute<MsiAction>("Action");
            if (actionTuple.Item1.HasValue && actionTuple.Item1.Value)
            {
                retVal.Action = actionTuple.Item2;
            }

            var startupTuple = includedRole.TryReadAttribute<WindowsServiceStartupType>("StartUpType");
            if (startupTuple.Item1.HasValue && startupTuple.Item1.Value)
            {
                foreach (var service in retVal.Services)
                {
                    service.StartupType = startupTuple.Item2;
                }
            }

            var disableTuple = includedRole.TryReadAttribute<bool>("DisableTests");
            if (disableTuple.Item1.HasValue && disableTuple.Item1.Value)
            {
                retVal.DisableTests = disableTuple.Item2;
            }

            retVal.MsiDeploy.Action = retVal.Action;
            retVal.MsiDeploy.Configuration = retVal.Configuration;
            retVal.MsiDeploy.Description = retVal.Description;

            retVal.MsiDeploy.Groups.Clear();
            retVal.MsiDeploy.Groups.AddRange(retVal.Groups);

            retVal.MsiDeploy.DisableTests = retVal.DisableTests;

            return retVal;
        }

        private void ProcessMsi(XElement rootNode, MsiDeploy msiDeploy, ref ValidationResult validationResult)
        {
            var childNode = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "MSI");

            if (childNode == null)
            {
                validationResult.AddError("ServiceDeploy element does not have an MSI element.");
                return;
            }

            var msi = msiDeploy.Msi;

            ParseElementValue(childNode, "id", Namespaces.CommonRole.XmlNamespace, () => msi.ProductCode, ref validationResult);
            ParseElementValue(childNode, "name", Namespaces.CommonRole.XmlNamespace, () => msi.Name, ref validationResult, ValidationAction.NotNullOrEmpty("ServiceDeploy - name"));
            ParseElementValue(childNode, "UpgradeCode", Namespaces.CommonRole.XmlNamespace, () => msi.UpgradeCode, ref validationResult);

            var xpathExpression = string.Format("{0}:parameters/{0}:parameter", Namespaces.CommonRole.Prefix);

            foreach (var element in childNode.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager))
            {
                var msiParam = new Parameter();
                ParseElementAttribute(element, "name", () => msiParam.Name, ref validationResult, ValidationAction.NotNullOrEmpty("ServiceDeployment - parameter - name"));
                ParseElementAttribute(element, "value", () => msiParam.Value, ref validationResult, ValidationAction.NotNullOrEmpty("ServiceDeployment - parameter - value"));
                ParseElementAttribute(element, "type", () => msiParam.Type, ref validationResult, ValidationAction.NotNullOrEmpty("ServiceDeployment - parameter - type"));

                msiDeploy.Parameters.Add(msiParam);
            }

            xpathExpression = string.Format("{0}:dlls/{0}:dll", Namespaces.CommonRole.Prefix);
            ParseElementAttribute(childNode.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager), "name", msiDeploy.Dlls, ref validationResult);
        }

        private void ProcessServices(XElement rootNode, IList<WindowsService> services, ref ValidationResult validationResult)
        {
            var xpathExpression = string.Format("{0}:Services/{0}:Service", Namespaces.CommonRole.Prefix);
            var childNodes = rootNode.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager);

            foreach (var childNode in childNodes)
            {
                var service = new WindowsService();
                ParseElementAttribute(childNode, "StartUpType", () => service.StartupType, ref validationResult);

                ParseElementValue(childNode, "Name", Namespaces.CommonRole.XmlNamespace, () => service.Name, ref validationResult, ValidationAction.NotNullOrEmpty("ServiceDeploy - Service - name"));
                ParseElementValue(childNode, "CurrentName", Namespaces.CommonRole.XmlNamespace, () => service.CurrentName, ref validationResult);
                ParseElementValue(childNode, "Credentials", Namespaces.CommonRole.XmlNamespace, () => service.Account.LookupName, ref validationResult);

                var testNode = childNode.Element(Namespaces.CommonRole.XmlNamespace + "TestInfo");

                if (testNode != null)
                {
                    ParseElementAttribute(testNode, "DisableTests", () => service.DisableTests, ref validationResult);
                    ParseElementAttribute(testNode, "VerificationWaitTimeMilliSeconds", () => service.VerificationWaitTimeMilliSeconds, ref validationResult, ValidationAction.GreaterThanZero("ServiceDeploy - VerificationWaitTimeMilliSeconds"));
                }

                var clusterInfoNode = childNode.Element(Namespaces.CommonRole.XmlNamespace + "ClusterInfo");

                if (clusterInfoNode != null)
                {
                    service.ClusterInfo = new ClusterInfo();
                    ParseElementValue(clusterInfoNode, "ResourceName", Namespaces.CommonRole.XmlNamespace, () => service.ClusterInfo.ResourceName, ref validationResult);
                }

                services.Add(service);
            }

            if (services.Count == 0)
            {
                validationResult.AddError("ServiceDeploy element does not have any Service elements.");
            }
        }
    }
}