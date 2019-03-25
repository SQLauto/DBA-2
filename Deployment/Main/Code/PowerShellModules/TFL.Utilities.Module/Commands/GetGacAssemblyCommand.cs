using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Management.Automation;
using System.Reflection;
using Deployment.Common;
using Tfl.PowerShell.Common;
using TFL.Utilities.GAC;

namespace TFL.Utilities.Commands
{
    [Cmdlet(VerbsCommon.Get, "GacAssembly", DefaultParameterSetName = "PartsSet")]
    [OutputType("System.Reflection.AssemblyName")]
    public class GetGacAssemblyCommand : PSCmdletBase
    {
        [Parameter(Position = 0, ParameterSetName = "PartsSet")]
        [ValidateNotNullOrEmpty]
        public string[] Name { get; set; }
        [Parameter(ParameterSetName = "PartsSet")]
        [ValidateNotNullOrEmpty]
        public string[] Version { get; set; }
        [Parameter(ParameterSetName = "PartsSet")]
        [ValidateNotNullOrEmpty]
        public string[] Culture { get; set; }
        [Parameter(ParameterSetName = "PartsSet")]
        [ValidateNotNullOrEmpty]
        public string[] PublicKeyToken { get; set; }
        [Parameter(ParameterSetName = "PartsSet")]
        [ValidateNotNullOrEmpty]
        [PSDefaultValue(Value = new [] { System.Reflection.ProcessorArchitecture.Amd64})]
        public ProcessorArchitecture[] ProcessorArchitecture { get; set; }
        [Parameter(Mandatory = true, Position = 0, ParameterSetName = "AssemblyNameSet", ValueFromPipeline = true)]
        [ValidateNotNullOrEmpty]
        public AssemblyName[] AssemblyName { get; set; }
        [Parameter]
        public SwitchParameter Latest { get; set; }

        protected override void ProcessRecord()
        {
            if (ParameterSetName == "AssemblyNameSet")
            {
                var matches = GlobalAssemblyCache.GetAssemblies().Intersect(AssemblyName);
                WriteObject(matches);
            }
            else
            {
                var comparer = new AssemblyNameStringComparer();

                var matches = GlobalAssemblyCache.GetAssemblies()
                    .Intersect(Name, an => an.Name, comparer)
                    .Intersect(Version?.Select(System.Version.Parse))
                    .Intersect(ParseCultures())
                    .Intersect(ProcessorArchitecture)
                    .Intersect(PublicKeyToken, an => an.GetPublicKeyTokenString(), comparer);

                if (Latest)
                {
                    var temp = new List<AssemblyName>();

                    //if we pass in latest, if we have two versions of an assembly,
                    //only return the lastest one.
                    var name = string.Empty;
                    AssemblyName previous = null;

                    foreach (var assemblyName in matches)
                    {
                        var current = assemblyName;

                        if (previous == null)
                        {
                            previous = current;
                            continue;
                        }

                        //TODO: Handle ProcessorArchitechture too in comparisions.
                        //so should bring highest version for each processor type.

                        if (current.Name.Equals(previous.Name, StringComparison.InvariantCultureIgnoreCase))
                        {
                            if (previous.Version < current.Version)
                            {
                                previous = current;
                                continue;
                            }

                            //keep previous


                        }
                        else
                        {
                            temp.Add(previous);
                            previous = null;
                        }

                    }

                    temp.Add(previous);

                    matches = temp;
                }

                WriteObject(matches);
            }
        }

        private IEnumerable<CultureInfo> ParseCultures()
        {
            if(Culture.IsNullOrEmpty())
                yield break;

            foreach (var culture in Culture)
            {
                if (culture.Equals("neutral", StringComparison.InvariantCultureIgnoreCase))
                    yield return CultureInfo.InvariantCulture;

                yield return CultureInfo.GetCultureInfo(culture);
            }
        }
    }

    internal class AssemblyNameStringComparer : IEqualityComparer<string>
    {
        public bool Equals(string left, string right)
        {
            if (left == null && right == null)
                return true;

            if (left == null || right == null)
                return false;

            if (right.StartsWith("*"))
                return left.EndsWith(right.TrimStart('*'), StringComparison.InvariantCultureIgnoreCase);

            if (right.EndsWith("*"))
                return left.StartsWith(right.TrimEnd('*'), StringComparison.InvariantCultureIgnoreCase);

            return left.Equals(right, StringComparison.InvariantCultureIgnoreCase);
        }

        public int GetHashCode(string obj)
        {
            unchecked // Overflow is fine, just wrap
            {
                var hash = 17;
                hash = hash * 23 + obj.GetHashCode();
                return hash;
            }
        }
    }
}