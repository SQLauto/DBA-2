using System.Activities;
using System.IO;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.VersionControl.Client;


namespace CustomBuildActivities.FileActivities
{
    [BuildActivity(HostEnvironmentOption.Agent)]
    public sealed class SetReadOnlyFlag : CodeActivity
    {
        [RequiredArgument]
        public InArgument<string> FileMask { get; set; }

        [RequiredArgument]
        public InArgument<bool> ReadOnlyFlagValue { get; set; }

        [RequiredArgument]
        public InArgument<Workspace> Workspace { get; set; }

        
        protected override void Execute(CodeActivityContext context)
        {
            var fileMask = context.GetValue(FileMask);
            var workspace = context.GetValue(Workspace);
            var readOnlyFlagValue = context.GetValue(ReadOnlyFlagValue);
            foreach (var folder in workspace.Folders)
            {
                foreach (var file in Directory.GetFiles(folder.LocalItem, fileMask, SearchOption.AllDirectories))
                {
                    var attributes = File.GetAttributes(file);
                    if (readOnlyFlagValue)
                        File.SetAttributes(file, attributes | FileAttributes.ReadOnly);
                    else File.SetAttributes(file, attributes & ~FileAttributes.ReadOnly);
                }

            }
        }
    }
}