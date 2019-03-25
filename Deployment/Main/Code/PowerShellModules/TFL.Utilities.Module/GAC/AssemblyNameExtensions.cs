using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Reflection;
using Deployment.Common;
// ReSharper disable PossibleMultipleEnumeration

namespace TFL.Utilities.GAC
{
    public static class AssemblyNameExtensions
    {
        public static string GetFullyQualifiedName(this AssemblyName assemblyName)
        {
            if (assemblyName.ProcessorArchitecture == ProcessorArchitecture.None)
                return assemblyName.FullName;
            return assemblyName.FullName + ", ProcessorArchitecture=" + assemblyName.ProcessorArchitecture.ToString().ToLower();
        }

        public static bool IsFullyQualified(this AssemblyName assemblyName)
        {
            return !string.IsNullOrEmpty(assemblyName.Name) && assemblyName.Version != null && assemblyName.CultureInfo != null && assemblyName.GetPublicKeyToken() != null;
        }

        public static IEnumerable<AssemblyName> Intersect(this IEnumerable<AssemblyName> assemblyNames, IEnumerable<string> values, Func<AssemblyName, string> selector, IEqualityComparer<string> comparer)
        {
            if (values.IsNullOrEmpty())
                return assemblyNames;

           return assemblyNames.SelectMany(an => values, (an, value) => new { an, value })
                .Where(pair => comparer.Equals(selector(pair.an), pair.value))
                .Select(pair => pair.an);
        }

        public static IEnumerable<AssemblyName> Intersect(this IEnumerable<AssemblyName> assemblyNames, IEnumerable<Version> values)
        {
            if (values.IsNullOrEmpty())
                return assemblyNames;

            return assemblyNames.SelectMany(an => values, (an, value) => new { an, value })
                .Where(pair => pair.an.Version.Equals(pair.value))
                .Select(pair => pair.an);
        }

        public static IEnumerable<AssemblyName> Intersect(this IEnumerable<AssemblyName> assemblyNames, IEnumerable<CultureInfo> values)
        {
            if (values.IsNullOrEmpty())
                return assemblyNames;

            return assemblyNames.SelectMany(an => values, (an, value) => new { an, value })
                .Where(pair => pair.value.Equals(pair.an.CultureInfo))
                .Select(temp => temp.an);
        }

        public static IEnumerable<AssemblyName> Intersect(this IEnumerable<AssemblyName> assemblyNames, IEnumerable<ProcessorArchitecture> values)
        {
            if (values.IsNullOrEmpty())
                return assemblyNames;

            return assemblyNames.SelectMany(an => values, (an, value) => new { an, value })
                .Where(pair => pair.value.Equals(pair.an.ProcessorArchitecture))
                .Select(temp => temp.an);
        }

        public static string GetPublicKeyTokenString(this AssemblyName assemblyName)
        {
            var token = assemblyName.GetPublicKeyToken();
            if (token == null || token.Length == 0)
                return null;

            return token.Select(x => x.ToString("x2")).Aggregate(string.Concat);
        }
    }
}
