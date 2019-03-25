using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;

namespace Deployment.Domain.Parameters
{
    public class PlaceholderMappings
    {
        private readonly Dictionary<string, PlaceholderMapping> _placeholders = new Dictionary<string, PlaceholderMapping>(StringComparer.InvariantCultureIgnoreCase);

        public string GetValue(string key)
        {
            if (!_placeholders.ContainsKey(key))
                throw new ApplicationException($"PlaceholderMappings does not contain mapping '{key}'");

            return _placeholders[key].Lookup;
        }

        public IDictionary<string, PlaceholderMapping> Dictionary => _placeholders;

        public void Add(string name, PlaceholderMapping mapping)
        {
            if (_placeholders.ContainsKey(name))
                throw new ApplicationException($"PlaceholderMappings already contains mapping '{name}'");

            _placeholders[name] = mapping;
        }

        public void Add(string name, string lookup)
        {
            if (_placeholders.ContainsKey(name))
                throw new ApplicationException($"PlaceholderMappings already contains mapping '{name}'");

            Add(name, new PlaceholderMapping(name, lookup));
        }

        public void Update(string name, PlaceholderMapping mapping)
        {
            if (!_placeholders.ContainsKey(name))
                throw new ApplicationException($"PlaceholderMappings does not contain mapping '{name}'");

            _placeholders[name] = mapping;
        }

        public bool ContainsKey(string name)
        {
            return _placeholders.ContainsKey(name);
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
            if (_placeholders == null || _placeholders.Count == 0)
            {
                return "PlaceholderMappings:Empty";
            }

            var builder = new StringBuilder();

            foreach (var kvp in _placeholders)
            {
                builder.Append("Name: ").Append(kvp.Value.Name)
                    .Append(" Lookup: ").AppendLine(kvp.Value.Lookup);
            }

            return builder.ToString();
        }
    }
}
