using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;

namespace Deployment.Domain.Parameters
{
    public class RigManifest
    {
        public string RigName { get; set; }
        public DateTime? CreatedDate { get; set; }

        private readonly Dictionary<string, string> _virtualMachines = new Dictionary<string, string>(StringComparer.InvariantCultureIgnoreCase);

        public RigManifest(string name, DateTime? createdDate)
        {
            RigName = name;
            CreatedDate = createdDate;
        }

        public string GetValue(string key)
        {
            if (!_virtualMachines.ContainsKey(key))
                throw new ApplicationException($"RigManifest does not contain machine '{key}'");

            return _virtualMachines[key];
        }

        public IDictionary<string, string> Dictionary => _virtualMachines;

        public void Add(string name, string ipAddress)
        {
            if (_virtualMachines.ContainsKey(name))
                throw new ApplicationException($"PlaceholderMappings already contains mapping '{name}'");

            _virtualMachines[name] = ipAddress;
        }

        public void Update(string name, string ipAddress)
        {
            if (!_virtualMachines.ContainsKey(name))
                throw new ApplicationException($"PlaceholderMappings does not contain mapping '{name}'");

            _virtualMachines[name] = ipAddress;
        }

        public bool ContainsKey(string name)
        {
            return _virtualMachines.ContainsKey(name);
        }

        public string ResolveValue(string rawValue)
        {
            var pattern = @"(?:\$\()(\w+)(?:\))";

            var matches = Regex.Matches(rawValue, pattern, RegexOptions.IgnoreCase);

            if (matches.Count == 0)
                return rawValue;

            var key = matches[0].Groups[1].Value;

            return GetValue(key);
        }

        public override string ToString()
        {
            if (_virtualMachines == null || _virtualMachines.Count == 0)
            {
                return "RigManifestMachines:Empty";
            }

            var builder = new StringBuilder();

            foreach (var kvp in _virtualMachines)
            {
                builder.Append("Name: ").Append(kvp.Key)
                    .Append(" IP address: ").AppendLine(kvp.Value);
            }

            return builder.ToString();
        }
    }
}
