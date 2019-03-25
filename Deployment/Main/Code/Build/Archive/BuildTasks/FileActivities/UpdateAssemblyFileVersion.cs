using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Activities;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.VersionControl.Client;

namespace CustomBuildActivities.FileActivities
{

    [BuildActivity(HostEnvironmentOption.Agent)]
    public sealed class UpdateAssemblyFileVersion : CodeActivity
    {
        [RequiredArgument]
        public InArgument<string> AssemblyInfoFileMask { get; set; }
        [RequiredArgument]
        public InArgument<string> SourcesDirectory { get; set; }
        [RequiredArgument]
        public InArgument<string> AssemblyFileVersion { get; set; }
        protected override void Execute(CodeActivityContext context)
        {
            var sourcesDirectory = context.GetValue(SourcesDirectory);
            var assemblyInfoFileMask = context.GetValue(AssemblyInfoFileMask);

            bool changedContents;
            foreach (var file in Directory.EnumerateFiles(sourcesDirectory, assemblyInfoFileMask, SearchOption.AllDirectories))
            {
                var text = File.ReadAllText(file);
                changedContents = false;
                // we want to find 'AssemblyVersion("1.0.0.0")' etc 
                foreach (var attribute in new[] { "AssemblyFileVersion" })
                {
                    var regex = new Regex(attribute + @"\("".*""\)");
                    var match = regex.Match(text);
                    if (!match.Success) continue;
                    text = regex.Replace(text, attribute + "(\"" + context.GetValue(AssemblyFileVersion) + "\")");
                    changedContents = true;
                }
                if (changedContents) File.WriteAllText(file, text);
            }


        }
    }
}
