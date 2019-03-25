using System.Collections.Generic;
using System.Xml.Linq;
using Deployment.Domain.Parameters;

namespace Deployment.Domain.Operations
{
    public interface IParameterService
    {
        DeploymentParameters GetParametersFromString(string text);
        DeploymentParameters GetParametersFromConfig(string configFilePath);
        DeploymentParameters GetParametersFromXDocument(XDocument document);
        RawParamValue GetRawParameterValue(string value);
        DeploymentParameters ParseDeploymentParameters(IPackagePathBuilder packagePathBuilder, string defaultConfig, string overrideConfig, string rigConfigFile = "", PlaceholderMappings mappings = null, RigManifest rigManifest = null);
        DeploymentParameters ParseDeploymentParameters(IDeploymentPathBuilder deploymentPathBuilder, string defaultConfig, string overrideConfig, IList<ICIBasePathBuilder> ciBuilders, string rigConfigFile = "", PlaceholderMappings mappings = null, RigManifest rigManifest = null);
        DeploymentParameters ReadDeploymentParameters(string parameterFile);
        string ResolveValue(string input, IList<Parameter> parameters);
        TryGetParam TryGetValue(RawParamValue rawParamValue, IDictionary<string, DeploymentParameter> parameters);
        string UpdateParameterValue(string original, string parameterName, string parameterValue);
        string UpdateParameterLookup(string original, string parameterName, string parameterValue);
        bool ValidateParameterList(DeploymentParameters sourceParameters, IDictionary<string, DeploymentParameter> deployParams);
        PlaceholderMappings GetPlaceholderMappings(IDeploymentPathBuilder deploymentPathBuilder, string config);

    }
}
