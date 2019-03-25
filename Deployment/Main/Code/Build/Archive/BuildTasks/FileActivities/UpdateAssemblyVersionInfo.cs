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
    public sealed class UpdateAssemblyVersionInfo : CodeActivity
    {
        [RequiredArgument]
        public InArgument<string> AssemblyInfoFileMask { get; set; }
        [RequiredArgument]
        public InArgument<string> SourcesDirectory { get; set; }
        [RequiredArgument]
        public InArgument<string> VersionFilePath { get; set; }
        [RequiredArgument]
        public InArgument<string> VersionFileName { get; set; }
        protected override void Execute(CodeActivityContext context)
        {
            var sourcesDirectory = context.GetValue(SourcesDirectory);
            var assemblyInfoFileMask = context.GetValue(AssemblyInfoFileMask);
            var versionFile = context.GetValue(VersionFilePath) + @"\" + context.GetValue(VersionFileName);  //Load the version info into memory
            var versionText = "1.0.0.0";
            if (File.Exists(versionFile)) versionText = File.ReadAllText(versionFile);
            var currentVersion = new Version(versionText);
            var newVersion = new Version(currentVersion.Major, currentVersion.Minor, currentVersion.Build + 1, currentVersion.Revision);
            File.WriteAllText(versionFile, newVersion.ToString());
            bool changedContents;
            foreach (var file in Directory.EnumerateFiles(sourcesDirectory, assemblyInfoFileMask, SearchOption.AllDirectories))
            {
                var text = File.ReadAllText(file);
                changedContents = false;
                // we want to find 'AssemblyVersion("1.0.0.0")' etc 
                foreach (var attribute in new[] { "AssemblyVersion", "AssemblyFileVersion" })
                {
                    var regex = new Regex(attribute + @"\(""\d+\.\d+\.\d+\.\d+""\)");
                    var match = regex.Match(text);
                    if (!match.Success) continue;
                    text = regex.Replace(text, attribute + "(\"" + newVersion + "\")");
                    changedContents = true;
                }
                if (changedContents) File.WriteAllText(file, text);
            }
        }
    }
}
