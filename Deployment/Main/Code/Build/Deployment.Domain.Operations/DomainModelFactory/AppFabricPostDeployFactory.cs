using System.Xml.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public sealed class AppFabricPostDeployFactory : BaseRoleFactory<AppFabricPostDeploy>
    {
        public AppFabricPostDeployFactory(string defaultConfig) : base(defaultConfig, new[] { @"config:PostDeployRole[@Name='TFL.PostDeploy']/config:AppFabricPostDeploy", "role:PostDeployRole[@Name='TFL.PostDeploy']/role:AppFabricPostDeploy" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new AppFabricPostDeploy(DefaultConfig);

            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                var child = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "AppFabricPostDeploy");

                ParseElementAttribute(child, "PortNumber", () => retVal.PortNumber, ref validationResult, ValidationAction.GreaterThanZero("AppFabricPostDeploy - PortNumber"));
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