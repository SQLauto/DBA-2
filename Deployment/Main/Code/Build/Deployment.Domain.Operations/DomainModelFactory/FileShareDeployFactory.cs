using System.Xml.Linq;
using System.Xml.XPath;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class FileShareDeployFactory : BaseRoleFactory<FileShareDeploy>
    {
        public FileShareDeployFactory(string defaultConfig) : base(defaultConfig, new [] { "config:ServerRole[@Name='TFL.FileShare']", "role:ServerRole[@Name='TFL.FileShare']" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new FileShareDeploy(DefaultConfig);
            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                var shareElement = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "FileShare");
                ParseElementValue(shareElement, "ShareName", Namespaces.CommonRole.XmlNamespace, () => retVal.ShareName, ref validationResult, ValidationAction.NotNullOrEmpty("FileShare ShareName cannot be null or empty"));
                ParseElementValue(shareElement, "FolderToShare", Namespaces.CommonRole.XmlNamespace, () => retVal.TargetPath, ref validationResult, ValidationAction.NotNullOrEmpty("FolderToShare ShareName cannot be null or empty"));
                ParseElementAttribute(shareElement, "Action", () => retVal.Action, ref validationResult);

                string xpathExpression = string.Format("{0}:Users/{0}:User", Namespaces.CommonRole.Prefix);
                foreach (var elem in shareElement.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager))
                {
                    var user = new FileShareUser();
                    ParseElementAttribute(elem, "name", () => user.Name, ref validationResult, ValidationAction.NotNullOrEmpty("FolderToShare user 'name' cannot be null or empty"));
                    ParseElementAttribute(elem, "type", () => user.AccountType, ref validationResult);
                    ParseElementAttribute(elem, "permissions", () => user.Permissions, ref validationResult);
                    retVal.Users.Add(user);
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