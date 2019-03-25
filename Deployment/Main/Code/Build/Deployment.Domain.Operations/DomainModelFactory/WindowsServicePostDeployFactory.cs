using System.Xml.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class WindowsServicePostDeployFactory : BaseRoleFactory<WindowsServicePostDeploy>
    {
        public WindowsServicePostDeployFactory(string defaultConfig) : base(defaultConfig, new [] { "config:PostDeployRole[@Name='TFL.PostDeploy']/config:WindowsServicePostDeploy", "role:PostDeployRole[@Name='TFL.PostDeploy']/role:WindowsServicePostDeploy" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new WindowsServicePostDeploy(DefaultConfig);

            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                var child = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "WindowsServicePostDeploy");

                ParseElementAttribute(child, "ServiceName", () => retVal.ServiceName, ref validationResult,ValidationAction.NotNullOrEmpty("WindowsServicePostDeploy - ServiceName"));
                ParseElementAttribute(child, "State", () => retVal.State, ref validationResult);
                ParseElementAttribute(child, "Action", () => retVal.Action, ref validationResult);

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