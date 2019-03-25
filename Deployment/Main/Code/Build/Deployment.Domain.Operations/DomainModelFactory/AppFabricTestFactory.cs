using System.Xml.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class AppFabricTestFactory : BaseRoleFactory<AppFabricTest>
    {
        public AppFabricTestFactory(string defaultConfig) : base(defaultConfig, new []{ "config:AppFabricTest", "role:AppFabricTest" })
        {

        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new AppFabricTest();

            ParseElementAttribute(rootNode, "Name", () => retVal.Name, ref validationResult);
            ParseElementAttribute(rootNode, "Groups", retVal.Groups, ref validationResult);

            ParseElementValue(rootNode, "HostName", Namespaces.DeploymentConfig.XmlNamespace, () => retVal.HostName, ref validationResult);
            ParseElementValue(rootNode, "CacheName", Namespaces.DeploymentConfig.XmlNamespace, () => retVal.CacheName, ref validationResult);

            var testInfo = rootNode.Element(Namespaces.DeploymentConfig.XmlNamespace + "TestInfo");
            if (testInfo != null)
            {
                ParseElementAttribute(testInfo, "Account", () => retVal.AccountName, ref validationResult);
            }

            return retVal;
        }
    }
}