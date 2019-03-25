using System.Xml.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class ServiceBrokerTestFactory : BaseRoleFactory<ServiceBrokerTest>
    {
        public ServiceBrokerTestFactory(string defaultConfig) : base(defaultConfig, new[] { "config:ServiceBrokerTest", "role:ServiceBrokerTest" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new ServiceBrokerTest();

            ParseElementAttribute(rootNode, "Name", () => retVal.Name, ref validationResult);
            ParseElementAttribute(rootNode, "Groups", retVal.Groups, ref validationResult);

            var children = rootNode.Elements(Namespaces.DeploymentConfig.XmlNamespace + "Sql");

            foreach (var element in children)
            {
                var test = new ServiceBrokerSqlTest();

                var child = rootNode.Element(Namespaces.DeploymentConfig.XmlNamespace + "ConnectionInfo");

                if (child != null)
                {
                    ParseElementAttribute(child, "UserName", () => test.UserName, ref validationResult);
                    ParseElementAttribute(child, "Password", () => test.Password, ref validationResult);
                }

                ParseElementValue(element, "DatabaseServer", Namespaces.DeploymentConfig.XmlNamespace, () => test.DatabaseServer, ref validationResult);
                ParseElementValue(element, "DatabaseInstance", Namespaces.DeploymentConfig.XmlNamespace, () => test.DatabaseInstance, ref validationResult);
                ParseElementValue(element, "TargetDatabase", Namespaces.DeploymentConfig.XmlNamespace, () => test.TargetDatabase, ref validationResult);
                ParseElementValue(element, "SqlScript", Namespaces.DeploymentConfig.XmlNamespace, () => test.SqlScript, ref validationResult);

                retVal.Tests.Add(test);
            }

            return retVal;
        }

        public override bool ValidateDomainObject(ServiceBrokerTest domainObject, ref ValidationResult validationResult,
            bool suppressStandardParseValidations = false)
        {
            return validationResult.Result;
        }
    }
}