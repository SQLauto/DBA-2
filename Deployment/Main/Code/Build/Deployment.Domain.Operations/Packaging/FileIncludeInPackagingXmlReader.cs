using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Deployment.Common.Xml;

namespace Deployment.Domain.Operations.Packaging
{
    internal class FileIncludeInPackagingXmlReader
    {
        internal static List<PackagingFileConfig> Read(string xmlFile)
        {
            // Validate schema
            string log = string.Empty;
            //if (!XmlLogicHelper.ValidateFileIncludeInPackagingFileSchema(xmlFile, ref log))
            //{
            //    throw new ApplicationException(string.Format("Parameters file '{0}' failed schema validation\r\n{1}", xmlFile, log));
            //}

            var packagingFileConfigs = new List<PackagingFileConfig>();

            var parametersElement = XElement.Load(xmlFile);

            foreach (var element in parametersElement.Elements().Where(e => e.Name.LocalName == "FileToPackage"))
            {
                var packagingFileConfig = new PackagingFileConfig
                {
                    DeploymentRoleName = XmlHelper.GetAttribute(element, "DeploymentRoleName"),
                    ParameterDirectoryPath = XmlHelper.GetAttribute(element, "ParameterDirectoryPath"),
                    ParameterFileName = XmlHelper.GetAttribute(element, "ParameterFileName")
                };

                packagingFileConfigs.Add(packagingFileConfig);
            }

            return packagingFileConfigs;
        }
    }
}
