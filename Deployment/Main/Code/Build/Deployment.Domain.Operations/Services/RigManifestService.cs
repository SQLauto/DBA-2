using System;
using Deployment.Common.Xml;
using Deployment.Domain.Parameters;
using Deployment.Schemas;
using System.IO;
using System.Xml.Linq;
using System.Xml.XPath;
using Deployment.Common;
using Deployment.Common.Logging;

namespace Deployment.Domain.Operations.Services
{
    public class RigManifestService : IRigManifestService
    {
        private readonly IDeploymentLogger _logger;

        public RigManifestService(IDeploymentLogger logger)
        {
            _logger = logger;
        }

        public RigManifest ReadRigManifest(string rigManifestFile)
        {
            return !File.Exists(rigManifestFile)
                ? new RigManifest(string.Empty, null)
                : ReadAndAssignRigManifest(rigManifestFile);
        }

        public RigManifest GetRigManifest(IPackagePathBuilder packagePathBuilder)
        {
            return GetRigManifest(packagePathBuilder.DeployRootDirectory);
        }

        public RigManifest GetRigManifest(IDeploymentPathBuilder deploymentPathBuilder)
        {
            return GetRigManifest(deploymentPathBuilder.DeployRootDirectory);
        }

        private RigManifest GetRigManifest(string deployRootDirectory)
        {
            RigManifest rigManifest = null;
            var rigManifestFilePath = Path.Combine(deployRootDirectory, "RigManifest.xml");
            if (File.Exists(rigManifestFilePath))
            {
                rigManifest = ReadRigManifest(rigManifestFilePath);
            }
            else
            {
                _logger?.WriteWarn($"RigManifest File '{rigManifestFilePath}' not found. No rig specific ip address lookups can be made.");
            }

            return rigManifest;
        }

        private RigManifest ReadAndAssignRigManifest(string filePath)
        {
            var schemas = SchemaHelper.GetDeploymentSchemas(SchemaNames.RigManifest);

            var valid = XmlHelper.ValidateXml(schemas, filePath);
            if (!valid.Item1)
            {
                throw new ApplicationException(
                    $"[ParameterService] RigManifest file '{filePath}' failed schema validation\r\n{valid.Item2}");
            }

            var rigManifestDocument = XDocument.Load(filePath);

            string rigName = rigManifestDocument.Root.GetAttribute("rigname");
            string createdDateAttr = rigManifestDocument.Root.GetAttribute("createddate");
            DateTime createdDate;
            DateTime? createdDate2 = null;
            if (DateTime.TryParse(createdDateAttr, out createdDate))
            {
                createdDate2 = createdDate;
            }

            var rigManifest = new RigManifest(rigName, createdDate2);

            var xpathExpression = string.Format("{0}:machines/{0}:machine", Namespaces.DeploymentConfig.Prefix);

            foreach (var machine in rigManifestDocument.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager))
            {
                rigManifest.Add(machine.ReadAttribute<string>("name"), machine.ReadAttribute<string>("ipv4address"));
            }

            return rigManifest;
        }
    }
}
