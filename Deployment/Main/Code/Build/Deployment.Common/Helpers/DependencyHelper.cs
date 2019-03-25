using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;

namespace Deployment.Common.Helpers
{
    public static class DependencyHelper
    {
        /// <summary>
        /// Return a list of all the (.Net) depenadancies for the given .net dll or exe
        /// Only those dependancies living in the same folder as the target will be returned
        /// No system or GAC'd dependancies will be returned
        /// </summary>
        /// <param name="assemblyPath"></param>
        /// <returns></returns>
        public static List<string> GetDependencies(string assemblyPath)
        {
            string directory = Path.GetDirectoryName(assemblyPath);
            if (directory == null) throw new ArgumentNullException(nameof(assemblyPath));
            var dependancies = new List<string> { assemblyPath };
            string configFile = $"{assemblyPath}.config";
            if (File.Exists(configFile))
                dependancies.Add(configFile);

            var targetAssembly = Assembly.ReflectionOnlyLoadFrom(assemblyPath);
            var assemblyNames = new List<AssemblyName>();
            var subList = new List<AssemblyName>(targetAssembly.GetReferencedAssemblies());
                //.Where(a=>!a.Name.StartsWith("System", StringComparison.InvariantCultureIgnoreCase) && !a.Name.Equals("mscorlib", StringComparison.InvariantCulture)));

            while (subList.Any())
            {
                assemblyNames.AddRange(subList);
                subList = GetDependencies(subList, directory);
                assemblyNames.AddRange(subList);
            }

            foreach (var assName in assemblyNames)
            {
                string path = Path.Combine(directory, $"{assName.Name}.dll");
                if (File.Exists(path) && !dependancies.Contains(path))
                {
                    dependancies.Add(path);
                }
            }

            return dependancies;
        }

        /// <summary>
        /// Return a list of all the (.Net) depenadancies in the given directory for the given assemblys
        /// </summary>
        /// <param name="assNames"></param>
        /// <param name="directory">the location of the target assemblys</param>
        /// <returns></returns>
        private static List<AssemblyName> GetDependencies(IEnumerable<AssemblyName> assNames, string directory)
        {
            var dependencies = new List<AssemblyName>();
            foreach (var assName in assNames)
            {
                dependencies.AddRange(GetDependencies(assName, directory));
            }

            return dependencies;
        }

        /// <summary>
        /// Return a list of all the (.Net) depenadancies in the given directory for the given assembly
        /// </summary>
        /// <param name="assName"></param>
        /// <param name="directory"></param>
        /// <returns></returns>
        private static IEnumerable<AssemblyName> GetDependencies(AssemblyName assName, string directory)
        {
            var dependancies = new List<AssemblyName>();
            try
            {
                string assemblyPath = Path.Combine(directory, $"{assName.Name}.dll");
                if (File.Exists(assemblyPath))
                {
                    var targetAssembly = Assembly.ReflectionOnlyLoadFrom(assemblyPath);  // do not use LoadFrom as it will not work remotley
                    dependancies.AddRange(targetAssembly.GetReferencedAssemblies());
                    //.Where(a => !a.Name.StartsWith("System", StringComparison.InvariantCultureIgnoreCase) && !a.Name.Equals("mscorlib", StringComparison.InvariantCulture)));
                }
            }
            // ReSharper disable EmptyGeneralCatchClause
            catch
            // ReSharper restore EmptyGeneralCatchClause
            {
                // I get crazy erors when running this method through a custom activity on the build server. Seems only to affect webdriver.dll
                // and only is reproducable when run via the build workflow.
                // Have no other option but to swallow this error, no logging set up so cant even log it
            }

            return dependancies;
        }
    }
}