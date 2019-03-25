using System;
using System.Collections.Generic;
using System.Linq;
using Deployment.Common.Xml;
using Deployment.Domain.Parameters;
using Deployment.Schemas;
using System.IO;
using System.Text.RegularExpressions;
using System.Xml;
using System.Xml.Linq;
using System.Xml.XPath;
using Deployment.Common;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;

namespace Deployment.Domain.Operations.Services
{
    public class ParameterService : IParameterService
    {
        private static readonly string parameterStartIdentifier = "$(";
        private static readonly string parameterEndIdentifier = ")";
        private const string IPLookupStartIdentifier = "#_";
        private const string IPLookupEndIdentifier = "_#";

        private readonly IDeploymentLogger _logger;

        public ParameterService(IDeploymentLogger logger)
        {
            _logger = logger;
        }

        public DeploymentParameters ParseDeploymentParameters(IPackagePathBuilder packagePathBuilder, string defaultConfig, string overrideConfig,
                string rigConfigFile = "", PlaceholderMappings mappings = null, RigManifest rigManifest = null)
        {
            ArgumentHelper.AssertNotNull(packagePathBuilder, nameof(packagePathBuilder));
            ArgumentHelper.AssertNotNullOrEmpty(defaultConfig, nameof(defaultConfig));

            var deploymentParameters = ParseDeploymentParameters(packagePathBuilder.ParametersRelativeDirectory, defaultConfig, overrideConfig,
                null, packagePathBuilder.UniqueEnvironmentParametersDirectory, mappings, rigManifest, rigConfigFile);

            return deploymentParameters;
        }

        public DeploymentParameters ParseDeploymentParameters(IDeploymentPathBuilder deploymentPathBuilder, string defaultConfig, string overrideConfig,
                IList<ICIBasePathBuilder> ciBuilders, string rigConfigFile = "", PlaceholderMappings mappings = null, RigManifest rigManifest = null)
        {
            ArgumentHelper.AssertNotNull(deploymentPathBuilder, nameof(deploymentPathBuilder));
            ArgumentHelper.AssertNotNullOrEmpty(defaultConfig, nameof(defaultConfig));

            var relativeDirectories = ciBuilders?.Select(o => o.ParametersRelativeDirectory).ToList();

            var deploymentParameters = ParseDeploymentParameters(deploymentPathBuilder.ParametersRelativeDirectory, defaultConfig, overrideConfig,
                relativeDirectories, deploymentPathBuilder.UniqueEnvironmentParametersDirectory, mappings, rigManifest, rigConfigFile);

            return deploymentParameters;
        }

        public DeploymentParameters ReadDeploymentParameters(string filePath)
        {
            var parameterFile = new ParameterFile(filePath, false);
            var deploymentParameters = new DeploymentParameters();

            if (!parameterFile.Exists)
                return deploymentParameters;

            var validationResult = new ValidationResult();

            var parameters = ParseParameterFile(parameterFile, ref validationResult);
            return ApplyEnvironmentParameters(deploymentParameters, parameterFile, parameters, ref validationResult, true);
        }

        public DeploymentParameters GetParametersFromString(string text)
        {
            // Changed to TryGetParam in line with Web Transforms - it identifies whether we're dealing with a standard replacement parameter or an IP lookup
            var deploymentParameters = new DeploymentParameters();

            if(string.IsNullOrWhiteSpace(text))
                return deploymentParameters;

            var indexParam = text.IndexOf(parameterStartIdentifier, StringComparison.InvariantCultureIgnoreCase);
            var indexLookup = text.IndexOf(IPLookupStartIdentifier, StringComparison.InvariantCultureIgnoreCase);

            // Find all regular parameters first
            while (indexParam >= 0 && indexParam + parameterStartIdentifier.Length < text.Length)
            {
                int nextIndex = text.IndexOf(parameterEndIdentifier, indexParam + parameterStartIdentifier.Length, StringComparison.InvariantCultureIgnoreCase);

                if (nextIndex < 0)
                    break;

                if (nextIndex > indexParam + parameterStartIdentifier.Length)
                {
                    // we have found a tokenised parameter
                    var parameterString = text.Substring(indexParam + parameterStartIdentifier.Length, nextIndex - indexParam - parameterStartIdentifier.Length);
                    var deploymentParameter = new DeploymentParameter(parameterString);
                    deploymentParameters.Add(parameterString, deploymentParameter);
                    indexParam = text.IndexOf(parameterStartIdentifier, nextIndex + parameterEndIdentifier.Length, StringComparison.InvariantCultureIgnoreCase);
                }
                else
                {
                    indexParam = nextIndex;
                }
            }
            // Now locate all the Lookups
            while (indexLookup >= 0 && indexLookup + IPLookupStartIdentifier.Length < text.Length)
            {
                var nextIndex = text.IndexOf(IPLookupEndIdentifier, indexLookup + IPLookupStartIdentifier.Length, StringComparison.InvariantCultureIgnoreCase);

                if (nextIndex < 0)
                    break;

                if (nextIndex > indexLookup + IPLookupStartIdentifier.Length)
                {
                    // we have found a tokenised parameter
                    var parameterString = text.Substring(indexLookup + IPLookupStartIdentifier.Length, nextIndex - indexLookup - IPLookupStartIdentifier.Length);
                    var deploymentParameter = new DeploymentParameter(parameterString, isLookup: true);
                    deploymentParameters.Add(deploymentParameter.Text, deploymentParameter);
                    indexLookup = text.IndexOf(IPLookupStartIdentifier, nextIndex + IPLookupEndIdentifier.Length, StringComparison.InvariantCultureIgnoreCase);
                }
                else
                {
                    indexLookup = nextIndex;
                }
            }

            return deploymentParameters;
        }

        public DeploymentParameters GetParametersFromXDocument(XDocument document)
        {
            var deploymentParameters = new DeploymentParameters();

            if (document.Root == null)
                return deploymentParameters;

            foreach (var docElement in document.Root.Descendants())
            {
                if (docElement.NodeType != XmlNodeType.Element)
                    continue;

                if (docElement.HasAttributes)
                {
                    var attributes = docElement.Attributes().Select(a => a.Value).ToList();

                    foreach (var attribute in attributes)
                    {
                        // This attribute is just the plain name - its lost the start end identifier to determine type (replace or lookup)
                        deploymentParameters.AddRange(GetParametersFromString(attribute));
                    }

                    continue;
                }

                if (docElement.HasElements)
                    continue;

                deploymentParameters.AddRange(GetParametersFromString(docElement.Value));
            }

            return deploymentParameters;
        }

        public DeploymentParameters GetParametersFromConfig(string configFilePath)
        {
            var doc = XDocument.Load(configFilePath);
            return GetParametersFromXDocument(doc);
        }

        public bool ValidateParameterList(DeploymentParameters sourceParameters, IDictionary<string, DeploymentParameter> deployParams)
        {
            var isValid = true;

            foreach (var parameter in sourceParameters.Dictionary)
            {
                if (deployParams.Any(param => param.Key.Equals(parameter.Key, StringComparison.InvariantCultureIgnoreCase)))
                    continue;

                if (parameter.Value.IsLookup)
                    continue;

                isValid = false;
                _logger?.WriteError($"Parameter '{parameter}' is not defined in parameters file.");
            }

            return isValid;
        }

        public string UpdateParameterValue(string original, string parameterName, string parameterValue)
        {
            var pattern = Regex.Escape(parameterStartIdentifier) + "{0}" + Regex.Escape(parameterEndIdentifier);
            pattern = string.Format(pattern, parameterName);
            var result = Regex.Replace(original, pattern, parameterValue, RegexOptions.IgnoreCase);  //regex.Replace(original, parameterValue);
            return result;
        }

        public RawParamValue GetRawParameterValue(string value)
        {
            var replacementStartIndex = value.IndexOf(parameterStartIdentifier, StringComparison.OrdinalIgnoreCase);
            var lookupStartIndex = value.IndexOf(IPLookupStartIdentifier, StringComparison.OrdinalIgnoreCase);

            string temp;
            var isLookup = false;
            if (replacementStartIndex > -1)
            {
                temp = value.Replace(parameterStartIdentifier, string.Empty).Replace(parameterEndIdentifier, string.Empty);
            }
            else if (lookupStartIndex > -1)
            {
                var lookupEndIndex = value.IndexOf(IPLookupEndIdentifier, StringComparison.OrdinalIgnoreCase);

                temp = value.Substring(lookupStartIndex + IPLookupStartIdentifier.Length, lookupEndIndex - lookupStartIndex - IPLookupEndIdentifier.Length);

                isLookup = true;
            }
            else
            {
                return new RawParamValue(null, false, false);
            }

            return new RawParamValue(temp, true, isLookup);
        }

        public TryGetParam TryGetValue(RawParamValue rawValue, IDictionary<string, DeploymentParameter> parameters)
        {
            DeploymentParameter deploymentParameter;

            var found = parameters.TryGetValue(rawValue.ParameterKey, out deploymentParameter);

            if (found)
                return new TryGetParam(deploymentParameter, true);

            var foundKey =
                parameters.Keys.FirstOrDefault(k => k.Equals(rawValue.ParameterKey, StringComparison.InvariantCultureIgnoreCase));

            // Must ensure that parameters[foundKey] has had isLookup set
            return foundKey == null
                ? new TryGetParam(rawValue, false)
                : new TryGetParam(parameters[foundKey], true); // , rawParamValue.IsLookup);
        }

        /// <summary>
        /// Only called by SSIS Deploy Role. Must be for parameterisation of Deployment Config
        /// Relate to story: 104886 Universal Deployment Parameterisation
        /// </summary>
        /// <param name="input"></param>
        /// <param name="parameters"></param>
        /// <returns></returns>
        public string ResolveValue(string input, IList<Parameter> parameters)
            => parameters.Aggregate(input, (current, parameter)
                => UpdateParameterValue(current, parameter.Name, parameter.Value));

        /*
            * The rules are:
            * Process the default Parameters first:
            *  (A) Read in global default parameters [If they exist].
            *  (B) Read in global override parameters [If they exist].
            *  (C) Read in the non-distributed default parameters [If they exist].
            *  (D) Read in all default distributed parameters ensuring there is uniqueness across distributed default parameters
            *      overriding non-distributed parameters as required [If they exist].
            *  (E) Apply non-distributed override parameters overriding parameters as required [If they exist].
            *  (F) Apply [read in] all override distributed parameters ensuring there is uniqueness across distributed override parameters
            *      overriding parameters as required[If they exist].
            *
            *  (Dynamic Config) Read in UniqueEnvironmentConfig file [if it exists]
            *  (Dynamic Config) Apply in the Rig specific parameter overrides [if they exist].
            *
            *  (G) Ensure that some parameters exist.
        */
        private DeploymentParameters ParseDeploymentParameters(string parametersRelativeDirectory, string defaultConfig, string overrideConfig,
                IList<string> parameterRelativeDirectories, string uniqueEnvironmentParametersDirectory,
                PlaceholderMappings mappings, RigManifest rigManifest, string rigConfigFile)
        {
            ArgumentHelper.AssertNotNullOrEmpty(parametersRelativeDirectory, nameof(parametersRelativeDirectory));

            var isDeploymentCi = !parameterRelativeDirectories.IsNullOrEmpty();
            var hasOverride = !string.IsNullOrWhiteSpace(overrideConfig) && !defaultConfig.Equals(overrideConfig, StringComparison.InvariantCultureIgnoreCase);

            //Parameters collection (return value)
            var deploymentParameters = new DeploymentParameters();

            //Start with default global parameters
            var parameterFile = GetGlobalParameterFile(parametersRelativeDirectory, defaultConfig);

            //parse global parameter file
            var validationResult = new ValidationResult();
            var parsedParameters = ParseParameterFile(parameterFile, ref validationResult, mappings, rigManifest);

            if (!validationResult.Result)
            {
                _logger?.WriteWarn("Validation of parameter parsing failed. Deployment will continue, but you should monitor results.");
                validationResult.ValidationErrors.ForEach(m=>_logger?.WriteWarn(m));
            }

            ApplyEnvironmentParameters(deploymentParameters, parameterFile, parsedParameters, ref validationResult);

            if (hasOverride)
            {
                _logger?.WriteLine($"Override config of {overrideConfig} is specified. Determine presence of global override parameters.");
                parameterFile = GetGlobalParameterFile(parametersRelativeDirectory, overrideConfig);
                parsedParameters = ParseParameterFile(parameterFile, ref validationResult, mappings, rigManifest);

                ApplyEnvironmentParameters(deploymentParameters, parameterFile, parsedParameters, ref validationResult, true);
            }

            //process team parameters
            var parameterFiles = isDeploymentCi
                ? GetDistributedParameterFiles(parameterRelativeDirectories, defaultConfig)
                : GetTeamParameterFiles(parametersRelativeDirectory, defaultConfig);

            parsedParameters =
                FlattenParametersAndValidate(parameterFiles, ref validationResult, mappings, rigManifest);

            ApplyEnvironmentParameters(deploymentParameters, ParameterFile.Empty, parsedParameters, ref validationResult, true);

            if (hasOverride)
            {
                _logger?.WriteLine($"Override config of {overrideConfig} is specified. Determine presence of local override parameters.");
                parameterFiles = isDeploymentCi
                    ? GetDistributedParameterFiles(parameterRelativeDirectories, overrideConfig)
                    : GetTeamParameterFiles(parametersRelativeDirectory, overrideConfig);

                parsedParameters =
                    FlattenParametersAndValidate(parameterFiles, ref validationResult, mappings, rigManifest);

                ApplyEnvironmentParameters(deploymentParameters, ParameterFile.Empty, parsedParameters, ref validationResult, true);
            }

            //TODO: ValidationResult processing
            // Verify
            if (!deploymentParameters.Dictionary.Any())
            {
                _logger?.WriteWarn("No global, default or overriden parameters were found. Exiting.");

                throw new FileNotFoundException(
                    $"No parameter files were found for default config [{defaultConfig}] or override config [{overrideConfig}]");
            }

            // (Dynamic Config)
            if (!string.IsNullOrEmpty(rigManifest?.RigName))
            {
                var rigParameterFile =
                    GetRigParameterFile(uniqueEnvironmentParametersDirectory, rigManifest, rigConfigFile);
                parsedParameters = ParseParameterFile(rigParameterFile, ref validationResult, mappings, rigManifest);
                ApplyEnvironmentParameters(deploymentParameters, rigParameterFile, parsedParameters, ref validationResult, true);
            }

            if (deploymentParameters.Dictionary.Any())
                return deploymentParameters;

            _logger?.WriteWarn("No DeploymentParameters were found for any config. Exiting.");
            throw new Exception(
                $"No parameters found in files even though one or more parameter files exist for default config [{defaultConfig}] or override config [{overrideConfig}]");
        }

        private DeploymentParameters ApplyEnvironmentParameters(DeploymentParameters parameters, ParameterFile parameterFile, Dictionary<string, DeploymentParameter> rigParameters, ref ValidationResult validationResult, bool allowOverride = false)
        {
            //RigParameters can be null - e.g. Global parameters are not mandatory, so if none are found
            //then this will be null.  If null, ignore and return.
            if (rigParameters == null)
            {
                if (!parameterFile.Equals(ParameterFile.Empty))
                    _logger?.WriteLine($"Parameters file {parameterFile.FileName} does not exist, or is empty. Skipping.");

                return parameters;
            }

            _logger?.WriteLine("Applying environment parameters for config.");

            foreach (var kvp in rigParameters)
            {
                if (!parameters.ContainsKey(kvp.Key))
                {
                    parameters.Add(kvp.Key, kvp.Value);
                }
                else
                {
                    if (allowOverride)
                    {
                        parameters.Update(kvp.Key, kvp.Value);
                        continue;
                    }

                    validationResult.AddError($"Duplicate key [{kvp.Key}] found in file [{parameterFile.FilePath}], has been previously processed these must be unique within a set of distributed parameter files.");
                }
            }

            return parameters;
        }

        private ParameterFile GetGlobalParameterFile(string parameterPath, string configuration)
        {
            var parameterFilePath = Path.Combine(parameterPath, $"{configuration}.Global.Parameters.xml");

            var parameterFile = new ParameterFile(parameterFilePath, false, configuration);

            return parameterFile;
        }

        private IList<ParameterFile> GetTeamParameterFiles(string parameterPath, string configuration)
        {
            var parameterFiles = new List<ParameterFile>();

            var parameterFilePath = Path.Combine(parameterPath, $"{configuration}.Parameters.xml");

            var parameterFile = new ParameterFile(parameterFilePath, false, configuration);
            parameterFiles.Add(parameterFile);

            var distributedParameterFiles = Directory.EnumerateFiles(parameterPath, $"{configuration}.*.Parameters.xml")
                .Where(o => !o.EndsWith("global.parameters.xml", StringComparison.InvariantCultureIgnoreCase));

            foreach (var distributedParameterFile in distributedParameterFiles)
            {
                parameterFile = new ParameterFile(distributedParameterFile, true, configuration);
                parameterFiles.Add(parameterFile);
            }

            return parameterFiles;
        }

        private IList<ParameterFile> GetDistributedParameterFiles(IList<string> parameterRelativeDirectories, string configuration)
        {
            var parameterFiles = new List<ParameterFile>();

            foreach (var relativeDirectory in parameterRelativeDirectories)
            {
                var parameterFilePath = Path.Combine(relativeDirectory, $"{configuration}.Parameters.xml");

                var parameterFile = new ParameterFile(parameterFilePath, false, configuration);
                parameterFiles.Add(parameterFile);

                var distributedParameterFiles = Directory.EnumerateFiles(relativeDirectory, $"{configuration}.*.Parameters.xml")
                    .Where(o => !o.EndsWith("global.parameters.xml", StringComparison.InvariantCultureIgnoreCase));

                foreach (var distributedParameterFile in distributedParameterFiles)
                {
                    parameterFile = new ParameterFile(distributedParameterFile, true, configuration);
                    parameterFiles.Add(parameterFile);
                }
            }

            return parameterFiles;
        }

        private ParameterFile GetRigParameterFile(string rigParameterDirectory, RigManifest rigManifest, string rigConfigFile)
        {
            var parameterFilePath = Path.Combine(rigParameterDirectory, rigConfigFile);

            return new ParameterFile(parameterFilePath, false, rigManifest.RigName);
        }

        private Dictionary<string, DeploymentParameter> FlattenParametersAndValidate(IEnumerable<ParameterFile> parameterFiles, ref ValidationResult validationResult, PlaceholderMappings mappings = null, RigManifest rigManifest = null)
        {
            var parameters = new Dictionary<string, DeploymentParameter>(StringComparer.InvariantCultureIgnoreCase);

            foreach (var parameterFile in parameterFiles)
            {
                var deploymentParameters = ParseParameterFile(parameterFile, ref validationResult, mappings, rigManifest);

                if (deploymentParameters == null) continue;

                foreach (var kvp in deploymentParameters)
                {
                    if (parameters.ContainsKey(kvp.Key))
                    {
                        validationResult.AddError($"Duplicate key [{kvp.Key}] found in file [{parameterFile.FilePath}], has been previously processed these must be unique within a set of distributed parameter files.");
                    }
                    else
                    {
                        parameters.Add(kvp.Key, kvp.Value);
                    }
                }
            }

            return parameters;
        }

        private Dictionary<string, DeploymentParameter> ParseParameterFile(ParameterFile parameterFile, ref ValidationResult validationResult, PlaceholderMappings mappings = null, RigManifest rigManifest = null)
        {
            if (!parameterFile.Exists)
                return null;

            var schemas = SchemaHelper.GetDeploymentSchemas(SchemaNames.Parameters);

            var valid = XmlHelper.ValidateXml(schemas, parameterFile.FilePath);
            if (!valid.Item1)
            {
                validationResult.AddError(
                    $"[ParameterService] Parameters file '{parameterFile.FilePath}' failed schema validation\r\n{valid.Item2}");
                return null;
            }

            var parameters = new Dictionary<string, DeploymentParameter>(StringComparer.InvariantCultureIgnoreCase);

            var parametersDocument = XDocument.Load(parameterFile.FilePath);

            var xpathExpression = string.Format("{0}:parameters/{0}:parameter", Namespaces.DeploymentConfig.Prefix);

            foreach (var parameterElement in parametersDocument.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager))
            {
                if (parameterElement.Attributes().Any(a=>a.Name.LocalName.Equals("value")) && parameterElement.HasElements)
                {
                    validationResult.AddError(
                        $"Parameter file '{parameterFile.FilePath} has value defined in both Attribute and Elements block, invalid value definition\r\n");
                    break;
                }

                var isEncoded = parameterElement.TryReadAttribute<bool>("EncodeValue");
                var name = parameterElement.ReadAttribute<string>("name");
                var value = parameterElement.HasElements
                    ? parameterElement.ReadChildElement<string>("value", Namespaces.DeploymentConfig.XmlNamespace)
                    : parameterElement.ReadAttribute<string>("value");

                // Dynamic Config - IP Replacement within parameter value
                if (value.Contains(IPLookupStartIdentifier) && value.Contains(IPLookupEndIdentifier))
                {
                    if (mappings != null && rigManifest != null)
                    {
                        int startIdx = value.IndexOf(IPLookupStartIdentifier, StringComparison.InvariantCultureIgnoreCase);
                        int endIdx = value.IndexOf(IPLookupEndIdentifier, StringComparison.InvariantCultureIgnoreCase);

                        string lookupName = value.Substring(startIdx + IPLookupStartIdentifier.Length, endIdx - startIdx - IPLookupStartIdentifier.Length);
                        string machineMap = mappings.GetValue(lookupName);
                        string ip = rigManifest.GetValue(machineMap);

                        value = UpdateParameterLookupInValue(value, lookupName, ip);
                    }
                    //else
                    //{
                    //    throw new ApplicationException($"IP Lookup found but one or both of PlceholderMappings and RigManifest were not provided\r\n{log}");
                    //}
                }

                if (parameters.ContainsKey(name))
                {
                    validationResult.AddError($"Duplicate key [{name}] found in file [{parameterFile.FilePath}], has been previously processed these must be unique within a file.");
                    continue;
                }

                parameters.Add(name, new DeploymentParameter(value,
                    !isEncoded.Item1.HasValue || !isEncoded.Item1.Value || isEncoded.Item2));
            }

            return parameters;
        }

        public PlaceholderMappings ParsePlaceholderMappings(string environment, string placeholderMappingsFile)
        {
            if (!File.Exists(placeholderMappingsFile))
                return new PlaceholderMappings();

            var file = new MappingsFile(environment, placeholderMappingsFile);
            ReadAndAssignMappings(file);

            return file.Mappings;
        }

        public string UpdateParameterLookup(string original, string parameterName, string parameterValue)
        {
            string pattern = Regex.Escape(IPLookupStartIdentifier) + "{0}" + Regex.Escape(IPLookupEndIdentifier);
            pattern = string.Format(pattern, parameterName);
            string result = Regex.Replace(original, pattern, parameterValue, RegexOptions.IgnoreCase);  //regex.Replace(original, parameterValue);
            return result;
        }

        public string UpdateParameterLookupInValue(string original, string lookupName, string lookupValue)
        {
            string pattern = Regex.Escape(IPLookupStartIdentifier) + "{0}" + Regex.Escape(IPLookupEndIdentifier);
            pattern = string.Format(pattern, lookupName);
            string result = Regex.Replace(original, pattern, lookupValue, RegexOptions.IgnoreCase);  //regex.Replace(original, parameterValue);
            return result;
        }

        private void ReadAndAssignMappings(MappingsFile mappingsFile)
        {
            var schemas = SchemaHelper.GetDeploymentSchemas(SchemaNames.DynamicPlaceholderMappings);

            var valid = XmlHelper.ValidateXml(schemas, mappingsFile.FilePath);
            if (!valid.Item1)
            {
                throw new ApplicationException(
                    $"[ParameterService] Mappings file '{mappingsFile.FilePath}' failed schema validation\r\n{valid.Item2}");
            }

            var mappings = new PlaceholderMappings();

            var mappingsDocument = XDocument.Load(mappingsFile.FilePath);

            var xpathExpression = string.Format("{0}:DynamicPlaceholderMappings/{0}:Placeholder", Namespaces.DeploymentConfig.Prefix);

            foreach (var placeholderElement in mappingsDocument.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager))
            {
                mappings.Add(placeholderElement.ReadAttribute<string>("Name"), placeholderElement.ReadAttribute<string>("Lookup"));
            }

            mappingsFile.Mappings = mappings;
        }

        public PlaceholderMappings GetPlaceholderMappings(IDeploymentPathBuilder deploymentPathBuilder, string config)
        {
            PlaceholderMappings mappings = null;
            var placeholderMappingsFileName = $"{config}.PlaceholderMappings.xml";
            var placeholderMappingsFilePath = Path.Combine(deploymentPathBuilder.PlaceholderMappingsDirectory, placeholderMappingsFileName);
            if (File.Exists(placeholderMappingsFilePath))
            {
                mappings = ParsePlaceholderMappings(config, placeholderMappingsFilePath);
            }
            else
            {
                _logger?.WriteWarn($"  Placeholder Mappings file '{placeholderMappingsFilePath}' not found. No rig specific ip address lookups will be made.");
            }
            return mappings;
        }

        class MappingsFile
        {
            public MappingsFile(string environment, string filePath)
            {
                Mappings = new PlaceholderMappings();
                Environment = environment;
                FilePath = filePath;
            }

            public string Environment { get; set; }
            public string FilePath { get; set; }
            public PlaceholderMappings Mappings { get; set; }
        }
    }

}
