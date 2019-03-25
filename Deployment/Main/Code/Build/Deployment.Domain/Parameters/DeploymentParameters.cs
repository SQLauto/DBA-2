using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;

namespace Deployment.Domain.Parameters
{
    public class DeploymentParameters
    {
        private readonly Dictionary<string, DeploymentParameter> _parameters = new Dictionary<string, DeploymentParameter>(StringComparer.InvariantCultureIgnoreCase);

        public string GetValue(string key)
        {
            if (!_parameters.ContainsKey(key))
                throw new ApplicationException($"DeploymentParameters does not contain parameter '{key}'");

            return _parameters[key].Text;
        }

        public IDictionary<string, DeploymentParameter> Dictionary => _parameters;

        public void AddRange(DeploymentParameters parameters)
        {
            foreach (var deploymentParameter in parameters.Dictionary)
            {
                Add(deploymentParameter.Key, deploymentParameter.Value);
            }
        }

        public void Add(string key, DeploymentParameter parameter)
        {
            // CHECKME: 112236: Currently this is a collection of strings which allows duplicated which are ignored later
            //                Changing this to be ignore dupe on add BUT Must verify what duplication this was throwing errors for previously.

            //if (_parameters.ContainsKey(key))
            //    throw new ApplicationException($"DeploymentParameters already contains parameter '{key}'");
            if (!_parameters.ContainsKey(key))
                _parameters[key] = parameter;
        }

        public void Add(string key, string value, bool encode = true)
        {
            if (_parameters.ContainsKey(key))
                throw new ApplicationException($"DeploymentParameters already contains parameter '{key}'");

            Add(key, new DeploymentParameter(value, encode));
        }

        public void Update(string key, DeploymentParameter parameter)
        {
            if (!_parameters.ContainsKey(key))
                throw new ApplicationException($"DeploymentParameters does not contain parameter '{key}'");

            _parameters[key] = parameter;
        }

        public void Update(string key, string value)
        {
            if (!_parameters.ContainsKey(key))
                throw new ApplicationException($"DeploymentParameters does not contain parameter '{key}'");

            var sourceParam = _parameters[key];

            var updatedParam = new DeploymentParameter(value, sourceParam.Encode, sourceParam.IsLookup);

            _parameters[key] = updatedParam;
        }
        public bool ContainsKey(string key)
        {
            return _parameters.ContainsKey(key);
        }

        public Tuple<bool, string> ResolveValue(string rawValue)
        {
            var pattern = @"(?:\$\()(\w+)(?:\))";

            var matches = Regex.Matches(rawValue, pattern, RegexOptions.IgnoreCase);

            if (matches.Count == 0)
                return Tuple.Create(false, rawValue);

            var key = matches[0].Groups[1].Value;

            return Tuple.Create(true, GetValue(key));
        }

        public DeploymentParameters RemoveStandardParameters()
        {
            var standardParameters = new List<string>()
            {
                "scriptPath", "path", "errorLogPath", "Environment", "databasename", "servername",
                "deploymentHelpersPath"
            };

            var parametersWithoutStd = new DeploymentParameters();
            foreach (var param in _parameters)
            {
                //if (standardParameters.Contains(param.Key))
                //{
                //    _parameters.Remove(param.Key);
                //}
                if (!standardParameters.Contains(param.Key))
                {
                    parametersWithoutStd.Add(param.Key, param.Value);
                }
            }

            return parametersWithoutStd;
        }

        public override string ToString()
        {
            if (_parameters == null || _parameters.Count == 0)
            {
                return "DeploymentParameters:Empty";
            }

            var builder = new StringBuilder();

            foreach (var kvp in _parameters)
            {
                builder.Append("Key: ").Append(kvp.Key)
                    .Append(" Value: ").AppendLine(kvp.Value.Text);
            }

            return builder.ToString();
        }
    }
}
