using System.Xml.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class WebServicePostDeployFactory : BaseRoleFactory<WebServicePostDeploy>
    {
        public WebServicePostDeployFactory(string defaultConfig) : base(defaultConfig, new [] { "config:PostDeployRole[@Name='TFL.PostDeploy']/config:WebServicePostDeploy", "role:PostDeployRole[@Name='TFL.PostDeploy']/role:WebServicePostDeploy" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new WebServicePostDeploy(DefaultConfig);

            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                var child = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "WebServicePostDeploy");

                ParseElementAttribute(child, "PortNumber", () => retVal.PortNumber, ref validationResult, ValidationAction.GreaterThanZero("WebServicePostDeploy - PortNumber"));
                //ParseElementAttribute(child, "WebServicePath", () => retVal.WebServicePath, ref validationResult, new ValidationAction<string> {Expresssion = t => !string.IsNullOrWhiteSpace(t), ErrorMessage = "WebServicePath cannot be null or empty."});
                ParseElementAttribute(child, "WebServicePath", () => retVal.WebServicePath, ref validationResult);
                ParseElementAttribute(child, "Timeout", () => retVal.Timeout, ref validationResult, ValidationAction.GreaterThanZero("WebServicePostDeploy - Timeout"));

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