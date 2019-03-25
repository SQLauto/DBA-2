using System;
using System.Linq;
using System.Xml.Linq;
using System.Xml.XPath;
using Deployment.Common;
using Deployment.Common.Xml;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class MsiDeployFactory : BaseRoleFactory<MsiDeploy>
    {
        public MsiDeployFactory(string defaultConfig) : base(defaultConfig, new [] {"config:ServerRole[@Name='TFL.MsiDeploy']", "role:ServerRole[@Name='TFL.MsiDeploy']" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new MsiDeploy {Configuration = DefaultConfig};

            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                var child = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "MsiDeploy");

                if (child == null)
                {
                    validationResult.AddError($"No MsiDeploy element was found for role {retVal.Name} ({retVal.Include}).");
                    return null;
                }

                ParseElementAttribute(child, "Action", () => retVal.Action, ref validationResult);

                ProcessMsi(child, retVal, ref validationResult);

                var xpathExpression = string.Format("{0}:Configs/{0}:config", Namespaces.CommonRole.Prefix);
                foreach (var config in child.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager))
                {
                    var msiConfig = new MsiConfig();
                    ParseElementAttribute(config, "name", () => msiConfig.Name, ref validationResult, ValidationAction.NotNullOrEmpty("MsiDeploy - config - name"));
                    ParseElementAttribute(config, "target", () => msiConfig.Target, ref validationResult, ValidationAction.NotNullOrEmpty("MsiDeploy - config - target"));

                    retVal.Configs.Add(msiConfig);
                }

                ParseElementAttribute(child.Element(Namespaces.CommonRole.XmlNamespace + "TestInfo"), "DisableTests", () => retVal.DisableTests, ref validationResult);

                ValidateDomainObject(retVal, ref validationResult, true);
            }
            catch (Exception ex)
            {
                validationResult.AddException(ex);
                return null;
            }

            return validationResult.Result ? retVal : null;
        }

        public override IBaseRole ApplyOverrides(IBaseRole commonRole, XElement includedRole, ref ValidationResult validationResult)
        {
            var retVal = (MsiDeploy)base.ApplyOverrides(commonRole, includedRole, ref validationResult);

            var actionTuple = includedRole.TryReadAttribute<MsiAction>("Action");
            if (actionTuple.Item1.HasValue && actionTuple.Item1.Value)
            {
                retVal.Action = actionTuple.Item2;
            }

            var disableTuple = includedRole.TryReadAttribute<bool>("DisableTests");
            if (disableTuple.Item1.HasValue && disableTuple.Item1.Value)
            {
                retVal.DisableTests = disableTuple.Item2;
            }

            return retVal;
        }

        public override bool ValidateDomainObject(MsiDeploy domainObject, ref ValidationResult validationResult,
            bool suppressStandardParseValidations = false)
        {
            bool productCodeSpecified = domainObject.Msi.ProductCode != null &&
                                           domainObject.Msi.ProductCode != default(Guid);
            bool upgradeCodeSpecified = domainObject.Msi.UpgradeCode != null &&
                                           domainObject.Msi.UpgradeCode != default(Guid);
            if (!productCodeSpecified && !upgradeCodeSpecified)
            {
                validationResult.AddError(
                    $"ServerRole '{domainObject.Name ?? "UNSPECIFIED"}' ({domainObject.Description ?? string.Empty}) must have at least one of the following specified [id] (which is the product code) or [UpgradeCode] in the MSI block.");
            }

            return validationResult.Result;
        }

        private void ProcessMsi(XElement rootNode, MsiDeploy msiDeploy, ref ValidationResult validationResult)
        {
            var childNode = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "MSI");

            if (childNode == null)
            {
                validationResult.AddError("MSIDeploy element does not have an MSI element.");
                return;
            }

            var msi = msiDeploy.Msi;

            ParseElementValue(childNode, "id", Namespaces.CommonRole.XmlNamespace, () => msi.ProductCode, ref validationResult);
            ParseElementValue(childNode, "name", Namespaces.CommonRole.XmlNamespace, () => msi.Name, ref validationResult, ValidationAction.NotNullOrEmpty("MsiDeploy - name"));
            ParseElementValue(childNode, "UpgradeCode", Namespaces.CommonRole.XmlNamespace, () => msi.UpgradeCode, ref validationResult);

            var xpathExpression = string.Format("{0}:parameters/{0}:parameter", Namespaces.CommonRole.Prefix);

            foreach (var element in childNode.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager))
            {
                var msiParam = new Parameter();
                ParseElementAttribute(element, "name", () => msiParam.Name, ref validationResult, ValidationAction.NotNullOrEmpty("MsiDeploy - parameter - name"));
                ParseElementAttribute(element, "value", () => msiParam.Value, ref validationResult, ValidationAction.NotNullOrEmpty("MsiDeploy - parameter - name"));
                ParseElementAttribute(element, "type", () => msiParam.Type, ref validationResult, ValidationAction.NotNullOrEmpty("MsiDeploy - parameter - name"));

                msiDeploy.Parameters.Add(msiParam);
            }

            xpathExpression = string.Format("{0}:parameters/{0}:usernameparameter", Namespaces.CommonRole.Prefix);

            var node = childNode.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager).FirstOrDefault();

            if (node != null)
            {
                var msiParam = new Parameter();
                ParseElementAttribute(node, "name", () => msiParam.Name, ref validationResult, ValidationAction.NotNullOrEmpty("MsiDeploy - usernameparameter - name"));
                ParseElementAttribute(node, "credential", () => msiParam.Value, ref validationResult, ValidationAction.NotNullOrEmpty("MsiDeploy - usernameparameter - name"));
                ParseElementAttribute(node, "name", () => msiParam.Type, ref validationResult, ValidationAction.NotNullOrEmpty("MsiDeploy - usernameparameter - name"));
            }

            xpathExpression = string.Format("{0}:parameters/{0}:passwordparameter", Namespaces.CommonRole.Prefix);

            node = childNode.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager).FirstOrDefault();

            if (node != null)
            {
                var msiParam = new Parameter();
                ParseElementAttribute(node, "name", () => msiParam.Name, ref validationResult, ValidationAction.NotNullOrEmpty("MsiDeploy - passwordparameter - name"));
                ParseElementAttribute(node, "credential", () => msiParam.Value, ref validationResult, ValidationAction.NotNullOrEmpty("MsiDeploy - passwordparameter - credential"));
                ParseElementAttribute(node, "type", () => msiParam.Type, ref validationResult, ValidationAction.NotNullOrEmpty("MsiDeploy - passwordparameter - type"));
            }

            xpathExpression = string.Format("{0}:dlls/{0}:dll", Namespaces.CommonRole.Prefix);
            ParseElementAttribute(childNode.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager), "name", msiDeploy.Dlls, ref validationResult);
        }
    }
}