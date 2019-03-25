using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text.RegularExpressions;
using System.Xml;
using System.Xml.Linq;
using Deployment.Common.Logging;
using Deployment.Domain.Parameters;

namespace Deployment.Domain.Operations.Services
{
    public class ConfigurationTransformationService
    {
        private readonly IParameterService _parameterService;
        private readonly IDeploymentLogger _logger;

        public ConfigurationTransformationService(IParameterService parameterService, IDeploymentLogger logger)
        {
            _parameterService = parameterService;
            _logger = logger;
        }

        public void UpdateWebConfigurationFiles(string packageFolderPath, string setParametersFile, string packageName)
        {
            string space = "  ";
            string value;
            string pattern = @"(?i)\\\\\w+\\*\.config\$";

            var scopeSearch = new Regex(pattern);
            IEnumerable<string> files = null;
            var setParametersXml = new XmlDocument();
            var parametersXml = new XmlDocument();

            setParametersXml.Load(setParametersFile);
            var setParameters = setParametersXml.GetElementsByTagName("setParameter").Cast<XmlNode>()
                .ToDictionary(setParameter => setParameter.Attributes["name"].Value, setParameter => setParameter.Attributes["value"].InnerText);

            string webPackage = packageFolderPath + "\\_PublishedWebsites\\" + packageName + "_Package\\" + packageName + ".zip";
            string webPackageFolderPath = packageFolderPath + "\\_PublishedWebsites\\" + packageName + "_Package\\" + packageName;

            Directory.CreateDirectory(webPackageFolderPath);
            Directory.CreateDirectory(webPackageFolderPath + "\\Content");

            using (var webArchive = ZipFile.OpenRead(webPackage))
            {
                foreach (var entry in webArchive.Entries)
                {
                    //must be xml and in the root
                    if (entry.FullName == "parameters.xml")
                    {
                        var fileToExtract = Path.Combine(webPackageFolderPath, entry.FullName);
                        entry.ExtractToFile(fileToExtract, true);
                    }
                }
            }

            string searchString = "PackageTmp";
            string searchStringBinFolder = "PackageTmp/bin";
            ICollection<ZipArchiveEntry> entriesCollection = new Collection<ZipArchiveEntry>();

            using (var archive = ZipFile.OpenRead(webPackage))
            {
                foreach (var entry in archive.Entries)
                {
                    /*
                     * Is in package & is a config file
                     * OR is a dll/exe in the bin folder so we can find the version of the assembly
                     */
                    if ((entry.FullName.Contains(searchString)
                        && entry.FullName.EndsWith(".config", StringComparison.InvariantCultureIgnoreCase))
                        ||
                        (entry.FullName.Contains(searchStringBinFolder)
                        && (entry.FullName.EndsWith(".dll", StringComparison.InvariantCultureIgnoreCase)
                        || entry.FullName.EndsWith(".exe", StringComparison.InvariantCultureIgnoreCase)))
                        )
                    {
                        entriesCollection.Add(entry);
                    }
                }

                foreach (var entry in entriesCollection)
                {
                    string relativePath = entry.FullName.Split(new[] {searchString}, StringSplitOptions.None).Last();
                    string fileToExtract = webPackageFolderPath + "\\Content" + relativePath.Replace("/", @"\");
                    string directoryToExtractTo = Path.GetDirectoryName(fileToExtract);

                    if (!Directory.Exists(directoryToExtractTo))
                    {
                        Directory.CreateDirectory(directoryToExtractTo);
                    }
                    entry.ExtractToFile(fileToExtract, true);
                }
            }

            parametersXml.Load(webPackageFolderPath + "\\parameters.xml");

            foreach (XmlNode parameter in parametersXml.GetElementsByTagName("parameter"))
            {
                if (setParameters.ContainsKey(parameter.Attributes["name"].Value))
                {
                    setParameters.TryGetValue(parameter.Attributes["name"].Value, out value);
                }
                else
                {
                    value = parameter.Attributes["defaultValue"].InnerText;
                }

                XmlNode parameterEntry = parameter.FirstChild;
                if (parameterEntry.Attributes != null && parameterEntry.Attributes["kind"].Value == "XmlFile")
                {
                    string scope = parameterEntry.Attributes["scope"].Value;
                    string match = parameterEntry.Attributes["match"].Value;
                    Match scopeMatch = scopeSearch.Match(scope);
                    string subScope = scopeMatch.Value;

                    files = Directory.GetFiles(webPackageFolderPath, "*", SearchOption.AllDirectories)
                        .Where(path => Regex.Match(path, subScope, RegexOptions.IgnoreCase).Success);

                    if (files.Any())
                    {
                        XmlDocument webConfigFile = new XmlDocument();
                        webConfigFile.Load(files.ElementAt(0));

                        XmlNode valueNode = webConfigFile.SelectSingleNode(match);
                        if (valueNode != null)
                        {
                            valueNode.Value = value;
                        }

                        webConfigFile.Save(files.ElementAt(0));
                        _logger?.WriteLine($"{space + space + space + parameter.Attributes["name"].Value} Done\r\n");
                    }
                    else
                    {
                        _logger?.WriteLine($"{space + space + space + parameter.Attributes["name"].Value} Failed\r\n");
                    }
                }
            }
        }

        public bool TransformApplicationConfiguration(string overrideConfig, string targetPath, string sourcePath, string configFileName,
                IDictionary<string, DeploymentParameter> parameters, PlaceholderMappings mappings, RigManifest rigManifest)
        {
            string newFileName;

            string overrideTransformConfigName = configFileName.Replace(".config", "." + overrideConfig + ".transform.config");
            string transformConfigName = configFileName.Replace(".config", ".transform.config");
            string envConfigName = configFileName.Replace(".config", "." + overrideConfig + ".config");

            string overrideConfigFullPath = Path.Combine(sourcePath, overrideTransformConfigName);
            string transformConfigFullPath = Path.Combine(sourcePath, transformConfigName);
            string environmentConfigFullPath = Path.Combine(sourcePath, envConfigName);

            string configFileFullPath = Path.Combine(sourcePath, configFileName);

            bool overrideConfigExists = File.Exists(overrideConfigFullPath);

            string transformConfigWithParametersFile = overrideConfigExists
                ? overrideConfigFullPath
                : File.Exists(transformConfigFullPath) ? transformConfigFullPath : null;

            configFileName = configFileName.Replace(".config", "");
            //var config = overrideConfigExists ? overrideConfig : "default"; //TODO: Get actual config value
            var config = overrideConfigExists ? overrideConfig : configFileName;

            if (!string.IsNullOrWhiteSpace(transformConfigWithParametersFile))
            {
                //TODO: Think about using an XmlReader instead etc. as we are doing for web transform below:
                using (var reader = new StreamReader(transformConfigWithParametersFile))
                {
                    var configFileText = reader.ReadToEnd();

                    foreach (var parameter in _parameterService.GetParametersFromString(configFileText).Dictionary)
                    {
                        var rawParamValue = new RawParamValue(parameter.Key, false, parameter.Value.IsLookup);

                        var found = _parameterService.TryGetValue(rawParamValue, parameters);

                        if ((!found.IsFound) && (!found.DeploymentParameter.IsLookup))
                            throw new ApplicationException(
                                $"Parameters file for '{config}' does not contain parameter '{parameter.Key}'");

                        if (!found.DeploymentParameter.IsLookup) // Use found parameter value from parameters collection
                        {
                            configFileText = _parameterService.UpdateParameterValue(configFileText, parameter.Key,
                                XmlEscapeString(found.DeploymentParameter));
                        }
                        else // Try and do an IP lookup
                        {
                            if (mappings == null || rigManifest == null)
                            {
                                throw new ApplicationException(
                                    $"IP lookup on '{found.DeploymentParameter.Text}' cannot be performed as both a placeholders mappings file and a rig manifest are required.");
                            }
                            else
                            {
                                // from value=http://#_BaselineWebIP_#"
                                // via mapping (BaselineWebIP -> Machine) -> IP
                                var mappedMachine = mappings.GetValue(parameter.Key);
                                var ip = rigManifest.GetValue(mappedMachine);

                                //valueNode.Value = valueNode.Value.Replace($"#_{value.ParameterKey}_#", ip);
                                configFileText = _parameterService.UpdateParameterLookup(configFileText, parameter.Key, ip);
                            }
                        }
                    }


                    if(overrideConfigExists)
                    {
                        newFileName = overrideTransformConfigName;
                        newFileName = newFileName.Replace(".transform", "");
                        newFileName = newFileName.Replace($".{overrideConfig}", "");
                    }
                    else
                    {
                        newFileName = transformConfigName;
                        newFileName = newFileName.Replace(".transform", "");
                    }


                    if (File.Exists(targetPath + "\\" + newFileName))
                        File.Delete(targetPath + "\\" + newFileName);

                    using (var writer = new StreamWriter(targetPath + "\\" + newFileName))
                    {
                        writer.Write(configFileText);
                    }
                }

                return true;
            }

            if (File.Exists(environmentConfigFullPath))
            {
                newFileName = envConfigName;
                newFileName = newFileName.Replace("." + overrideConfig, string.Empty);

                string newFileFullPath = Path.Combine(targetPath, newFileName);

                if (File.Exists(newFileFullPath))
                    File.Delete(newFileFullPath);

                File.Move(Path.Combine(targetPath, envConfigName), newFileFullPath);

                return true;
            }

            if (!File.Exists(configFileFullPath))
            {
                string errorMessage = $"Unable to find config file: [{configFileFullPath}] for transformation.";
                throw new FileNotFoundException(errorMessage, configFileFullPath);
            }

            File.Copy(configFileFullPath, Path.Combine(targetPath, configFileName), true);

            return true;
        }

        public bool TransformWebParametersFile(string setParametersFile, string config, IDictionary<string, DeploymentParameter> parameters,
                IDictionary<string, string> webDeployCorrections, PlaceholderMappings mappings, RigManifest rigManifest)
        {
            string overrideTransformParameters = setParametersFile.Replace(".xml", "." + config + ".transform.xml");
            string transformParams = setParametersFile.Replace(".xml", ".transform.xml");

            transformParams = File.Exists(overrideTransformParameters)
                ? overrideTransformParameters
                : File.Exists(transformParams) ? transformParams : null;

            if (string.IsNullOrEmpty(transformParams))
                throw new FileNotFoundException("Cannot find a web transform parameters file.");

            var fileInfo = new FileInfo(setParametersFile);

            if (fileInfo.Exists)
                fileInfo.IsReadOnly = false;

            var document = XElement.Load(transformParams);

            foreach (var element in document.Elements().Where(e => e.Name.LocalName == "setParameter"))
            {
                var valueNode = element.Attribute("value");

                if (valueNode == null)
                    throw new ApplicationException(
                        $"Parameters file for '{config}' does not valid SetParameters");

                var nameNode = element.Attribute("name");
                var name = nameNode.Value;

                if (webDeployCorrections != null && webDeployCorrections.ContainsKey(name))
                {
                    var correction = webDeployCorrections[name];
                    valueNode.Value = correction;
                }

                //strip away placeholders to get value
                var rawParameterValue = _parameterService.GetRawParameterValue(valueNode.Value);

                if (!rawParameterValue.IsValid)
                    continue;

                // This locates parameters.xml files containing specific values b environment.
                var found = _parameterService.TryGetValue(rawParameterValue, parameters);

                if ((!found.IsFound) && (!found.DeploymentParameter.IsLookup))
                    throw new ApplicationException(
                        $"Parameters file for '{config}' does not contain parameter '{rawParameterValue.ParameterKey}'");

                if (!found.DeploymentParameter.IsLookup) // Use found parameter value from parameters collection
                {
                    valueNode.Value = found.DeploymentParameter.Text;
                }
                else // Try and do an IP lookup
                {
                    if (mappings == null || rigManifest == null)
                    {
                        throw new ApplicationException(
                            $"IP lookup on '{valueNode.Value}' cannot be performed as one or both of mappings file or rigmanifest is not present");
                    }

                    // from value=http://#_BaselineWebIP_#"
                    // via mapping (BaselineWebIP -> Machine) -> IP
                    var mappedMachine = mappings.GetValue(rawParameterValue.ParameterKey);
                    var ip = rigManifest.GetValue(mappedMachine);
                    valueNode.Value = valueNode.Value.Replace($"#_{rawParameterValue.ParameterKey}_#", ip);
                }
            }

            using (var writer = new StreamWriter(setParametersFile))
            {
                document.Save(writer);
            }

            return true;
        }

        private string XmlEscapeString(DeploymentParameter inputValue)
        {
            if (!inputValue.Encode)
                return inputValue.Text;

            string xtext = new XText(inputValue.Text).ToString();
            return xtext.Replace("\"", "&quot;");
        }
    }
}
