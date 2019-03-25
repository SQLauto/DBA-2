using System.Linq;
using System.Xml.Linq;
using System.Xml.XPath;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class EventLogDeployFactory : BaseRoleFactory<EventLogDeploy>
    {
        public EventLogDeployFactory(string defaultConfig) : base(defaultConfig, new[] { @"config:ServerRole[@Name='TFL.EventLogDeploy']", "role:ServerRole[@Name='TFL.EventLogDeploy']" })
        {

        }
        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new EventLogDeploy(DefaultConfig);

            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                var child = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "EventLogDeploy");

                ParseElementAttribute(child, "EventLogName", () => retVal.EventLogName, ref validationResult, ValidationAction.NotNullOrEmpty("EventLogName has not been specified"));
                ParseElementAttribute(child, "MaxLogSizeInKiloBytes", () => retVal.MaxLogSizeInKiloBytes, ref validationResult, ValidationAction.GreaterThanZero("EventLogDeploy - MaxLogSizeInKiloBytes"));
                ParseElementAttribute(child, "DisablePostDeploymentTests", () => retVal.DisablePostDeploymentTests, ref validationResult);
                ParseElementAttribute(child, "Action", () => retVal.Action, ref validationResult);

                var xpathExpression = string.Format(@"{0}:Sources/{0}:Source", Namespaces.CommonRole.Prefix);
                ParseElementAttribute(child.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager), "Name", retVal.Sources, ref validationResult);

                if (retVal.Sources.Count == 0 || retVal.Sources.Any(string.IsNullOrWhiteSpace))
                {
                    validationResult.AddError("No Event Log Sources found.");
                    return null;
                }

                ValidateDomainObject(retVal, ref validationResult, true);
            }
            catch (System.Exception ex)
            {
                validationResult.AddException(ex);
                return null;
            }

            return validationResult.Result ? retVal : null;
        }
    }
}