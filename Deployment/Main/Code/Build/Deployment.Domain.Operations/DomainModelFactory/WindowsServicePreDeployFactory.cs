using System.Xml.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class WindowsServicePreDeployFactory : BaseRoleFactory<WindowsServicePreDeploy>
    {
        public WindowsServicePreDeployFactory(string defaultConfig) : base(defaultConfig, new [] { "config:PreDeployRole[@Name='TFL.PreDeploy']/config:WindowsServicePreDeploy", "role:PreDeployRole[@Name='TFL.PreDeploy']/role:WindowsServicePreDeploy" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new WindowsServicePreDeploy(DefaultConfig);

            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                var child = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "WindowsServicePreDeploy");

                ParseElementAttribute(child, "ServiceName", () => retVal.ServiceName, ref validationResult, ValidationAction.NotNullOrEmpty("WindowsServicePreDeploy - ServiceName"));
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