using System;
using System.Xml.Linq;
using System.Xml.XPath;
using Deployment.Common;
using Deployment.Domain.Roles;
using System.Collections.Generic;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class SsisDeployFactory : BaseRoleFactory<SsisDeploy>
    {
        public SsisDeployFactory(string defaultConfig) : base(defaultConfig, new[] { "config:ServerRole[@Name='TFL.SsisDeploy']", "role:ServerRole[@Name='TFL.SsisDeploy']" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new SsisDeploy();

            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                var child = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "SsisDeploy");

                if (child == null)
                {
                    validationResult.AddError("SsisDeploy element was not found.");
                    return null;
                }

                ParseElementValue(child, "SSISEnvironment", Namespaces.CommonRole.XmlNamespace, () => retVal.Environment, ref validationResult, ValidationAction.NotNullOrEmpty("SSISEnvironment cannot be null or empty."));
                ParseElementValue(child, "SSISFolder", Namespaces.CommonRole.XmlNamespace, () => retVal.Folder, ref validationResult, ValidationAction.NotNullOrEmpty("SSISFolder cannot be null or empty."));
                ParseElementValue(child, "DatabaseInstance", Namespaces.CommonRole.XmlNamespace, () => retVal.DatabaseInstance, ref validationResult, ValidationAction.NotNullOrEmpty("DatabaseInstance cannot be null or empty."));
                ParseElementValue(child, "DeployMode", Namespaces.CommonRole.XmlNamespace, () => retVal.DeploymentMode, ref validationResult);

                ProcessProject(child.Element(Namespaces.CommonRole.XmlNamespace + "Project"), retVal, ref validationResult);

                retVal.TestInfo = ProcessTestInfo(child, ref validationResult);

                ValidateDomainObject(retVal, ref validationResult, true);
            }
            catch (Exception ex)
            {
                validationResult.AddException(ex);
                return null;
            }

            return validationResult.Result ? retVal : null;
        }

        private void ProcessProject(XElement rootNode, SsisDeploy ssisDeploy, ref ValidationResult validationResult)
        {
            if (rootNode == null)
            {
                validationResult.AddError("Project element was not found.");
                return;
            }

            ParseElementValue(rootNode, "Name", Namespaces.CommonRole.XmlNamespace, () => ssisDeploy.ProjectName, ref validationResult, ValidationAction.NotNullOrEmpty("Project Name cannot be null or empty."));
            ParseElementValue(rootNode, "SsisFile", Namespaces.CommonRole.XmlNamespace, () => ssisDeploy.SsisFile, ref validationResult, ValidationAction.NotNullOrEmpty("Project SsisFile cannot be null or empty."));
            ParseElementValue(rootNode, "Type", Namespaces.CommonRole.XmlNamespace, () => ssisDeploy.ProjectType, ref validationResult, ValidationAction.NotNullOrEmpty("Project Type cannot be null or empty."));

            var xpathExpression = string.Format("{0}:Packages/{0}:Package", Namespaces.CommonRole.Prefix);
            ParseElementAttribute(rootNode.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager), "Name", ssisDeploy.Packages, ref validationResult);

            xpathExpression = string.Format("{0}:parameters/{0}:parameter", Namespaces.CommonRole.Prefix);

            foreach (var parameterNode in rootNode.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager))
            {
                var param = new Parameter();

                ParseElementAttribute(parameterNode, "name", () => param.Name, ref validationResult, ValidationAction.NotNullOrEmpty("Parameter name cannot be null or empty."));
                ParseElementAttribute(parameterNode, "value", () => param.Value, ref validationResult, ValidationAction.NotNullOrEmpty("Parameter value cannot be null or empty."));
                ParseElementAttribute(parameterNode, "type", () => param.Type, ref validationResult, ValidationAction.NotNullOrEmpty("Parameter type cannot be null or empty."));
                ParseElementAttribute(parameterNode, "description", () => param.Description, ref validationResult);

                ssisDeploy.Parameters.Add(param);
            }
        }

        private SsisTestInfo ProcessTestInfo(XElement rootNode, ref ValidationResult validationResult)
        {
            var childNode = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "TestInfo");

            if (childNode == null)
            {
                return null;
            }

            var webTestInfo = new SsisTestInfo();

            ParseElementAttribute(childNode, "SqlUserName", () => webTestInfo.SqlUserName, ref validationResult, ValidationAction.NotNullOrEmpty("SsisDeploy - TestInfo - SqlUserName"));
            ParseElementAttribute(childNode, "SqlPassword", () => webTestInfo.SqlPassword, ref validationResult, ValidationAction.NotNullOrEmpty("SsisDeploy - TestInfo - SqlPassword"));

            return webTestInfo;
        }

        public override IBaseRole UpdateParameterisedValues(IBaseRole deployRole, IParameterService parameterService, IDeploymentPathBuilder deploymentPathBuilder, IList<ICIBasePathBuilder> ciPathBuilders, ref ValidationResult validationResult)
        {
            try
            {
                var deploymentParameters = parameterService.ParseDeploymentParameters(deploymentPathBuilder, DefaultConfig, deployRole.Configuration, ciPathBuilders, null, null);

                foreach (var parameter in ((SsisDeploy)deployRole).Parameters)
                {
                    var resolveValue = deploymentParameters.ResolveValue(parameter.Value);

                    if(resolveValue.Item1)
                        parameter.Value = resolveValue.Item2;
                }
            }
            catch (Exception ex)
            {
                validationResult.AddException(ex);
                return null;
            }

            return validationResult.Result ? deployRole : null;
        }
    }
}