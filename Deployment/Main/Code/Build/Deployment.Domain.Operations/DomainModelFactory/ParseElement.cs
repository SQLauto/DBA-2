using System.Xml.Linq;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public struct ParseElement
    {
        private readonly XElement _element;
        private readonly int _ordinal;

        public ParseElement(XElement element, int ordinal)
        {
            _element = element;
            _ordinal = ordinal;
        }

        public XElement Element { get { return _element; } }
        public int Ordinal { get { return _ordinal; } }
    }

    public static class ParseElements
    {
        public const string Machine = "machine";
        public const string CommonRoleFile = "CommonRoleFile";
        public const string ServiceBrokerTest = "ServiceBrokerTest";
        public const string AppFabricTest = "AppFabricTest";
        public const string PostDeploymentTestIdentity = "PostDeploymentTestIdentity";
        public const string CustomTests = "CustomTests";

    }
}