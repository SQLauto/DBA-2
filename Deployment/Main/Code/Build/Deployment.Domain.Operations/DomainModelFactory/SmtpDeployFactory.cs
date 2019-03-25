using System.Xml.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class SmtpDeployFactory : BaseRoleFactory<SmtpDeploy>
    {
        public SmtpDeployFactory(string defaultConfig) : base(defaultConfig, new[] { "config:ServerRole[@Name='TFL.SMTPDeploy']", "role:ServerRole[@Name='TFL.SMTPDeploy']" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new SmtpDeploy();

            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                 var child = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "SMTPDeploy");

                if (child == null)
                {
                    validationResult.AddError("SMTPDeploy element was not found.");
                    return null;
                }

                ParseElementValue(child, "DropFolderLocation", Namespaces.CommonRole.XmlNamespace, () => retVal.DropFolderLocation, ref validationResult, ValidationAction.NotNullOrEmpty("SmtpDeploy - DropFolderLocation"));
                ParseElementValue(child, "ForwardingMailSmtp", Namespaces.CommonRole.XmlNamespace, () => retVal.ForwardingMailSmtp, ref validationResult, ValidationAction.NotNullOrEmpty("SmtpDeploy - ForwardingMailSmtp"));

                ValidateDomainObject(retVal, ref validationResult, true);
            }
            catch (System.Exception ex)
            {
                validationResult.AddException(ex);
                return null;
            }

            return validationResult.Result ? retVal : null;
        }

        public override bool ValidateDomainObject(SmtpDeploy domainObject, ref ValidationResult validationResult,
            bool suppressStandardParseValidations = false)
        {
            return validationResult.Result;
        }
    }
}