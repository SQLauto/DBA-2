using System.Xml;
using System.Xml.Linq;

namespace Deployment.Common
{
    public static class Namespaces
    {
        static Namespaces()
        {
            DeploymentConfig = new Namespace { Prefix = "config", XmlNamespace = "http://tfl.gov.uk/DeploymentConfig" };
            CommonRole = new Namespace { Prefix = "role", XmlNamespace = "http://tfl.gov.uk/CommonRoles" };

            NamespaceManager = new XmlNamespaceManager(new NameTable());
            NamespaceManager.AddNamespace(DeploymentConfig.Prefix, DeploymentConfig.XmlNamespace.ToString());
            NamespaceManager.AddNamespace(CommonRole.Prefix, CommonRole.XmlNamespace.ToString());
        }
        public static Namespace DeploymentConfig { get; set; }
        public static Namespace CommonRole { get; set; }

        public static XmlNamespaceManager NamespaceManager { get; set; }
    }

    public class Namespace
    {
        public string Prefix { get; set; }
        public XNamespace XmlNamespace { get; set; }
    }
}