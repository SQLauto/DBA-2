
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

namespace Deployment.Domain.Parameters
{
    public struct ParameterFile : IEquatable<ParameterFile>
    {
        private const string Pattern = @"((?:\w+)(?:\.\w+)*)(?:\.Parameters\.xml)";

        public ParameterFile(string filePath, bool isDistributedConfig, string configuration = null)
        {
            FilePath = filePath;
            Exists = !string.IsNullOrWhiteSpace(FilePath) && File.Exists(filePath);
            IsDistibutedConfig = isDistributedConfig;

            FileName = Path.GetFileName(filePath) ?? string.Empty;

            Configuration = string.IsNullOrWhiteSpace(configuration) && !string.IsNullOrWhiteSpace(FileName)
                ? Regex.Match(FileName, Pattern, RegexOptions.IgnoreCase).Captures[0].Value
                : string.Empty;
        }

        public string Configuration { get; }
        public bool IsDistibutedConfig { get; }
        public bool Exists { get; }
        public string FilePath { get; }
        public string FileName { get; set; }

        public static ParameterFile Empty => new ParameterFile(null, false);

        public override bool Equals(object obj)
        {
            return obj is ParameterFile && Equals((ParameterFile)obj);
        }

        public bool Equals(ParameterFile other)
        {
            return FilePath == other.FilePath &&
                   Configuration == other.Configuration &&
                   IsDistibutedConfig == other.IsDistibutedConfig;
        }

        public override int GetHashCode()
        {
            unchecked // Overflow is fine, just wrap
            {
                var hash = 17;
                hash = hash * 23 + (string.IsNullOrEmpty(FilePath) ? 0 : FilePath.ToLowerInvariant().GetHashCode());
                hash = hash * 23 + (string.IsNullOrEmpty(Configuration) ? 0 : Configuration.ToLowerInvariant().GetHashCode());
                hash = hash * 23 + IsDistibutedConfig.GetHashCode();
                return hash;
            }
        }
    }
}
