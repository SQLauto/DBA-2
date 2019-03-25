using System.Xml.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public sealed class SsisSetupFactory : BaseRoleFactory<SsisSetup>
    {
        public SsisSetupFactory(string defaultConfig) : base(defaultConfig, new[] { "config:ServerRole[@Name='TFL.SsisSetup']", "role:ServerRole[@Name='TFL.SsisSetup']" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new SsisSetup();

            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                var child = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "SsisSetup");

                if (child == null)
                {
                    validationResult.AddError("SsisSetup element was not found.");
                    return null;
                }

                ParseElementAttribute(child, "SSISDBInstance", () => retVal.SsisDbInstance, ref validationResult, ValidationAction.NotNullOrEmpty("SsisSetup - SSISDBInstance"));

                ValidateDomainObject(retVal, ref validationResult, true);
            }
            catch (System.Exception ex)
            {
                validationResult.AddException(ex);
                return null;
            }

            return validationResult.Result ? retVal : null;
        }

        public override IBaseRole ApplyOverrides(IBaseRole commonRole, XElement includedRole, ref ValidationResult validationResult)
        {
            var role = (SsisSetup)base.ApplyOverrides(commonRole, includedRole, ref validationResult);

            ParseElementAttribute(includedRole, "SSISDBInstance", () => role.SsisDbInstance, ref validationResult);

            return role;
        }
    }
}