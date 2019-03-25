using System.Activities;
using System.IO;
using System.Collections;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.VersionControl.Client;

namespace CustomBuildActivities.FileActivities
{
    [BuildActivity(HostEnvironmentOption.Agent)]
    public sealed class SetReadOnlyFlags : CodeActivity
    {
        [RequiredArgument]
        public InArgument<string[]> FilesToSet { get; set; }
        
        [RequiredArgument]
        public InArgument<bool> ReadOnlyFlagValue { get; set; }

        protected override void Execute(CodeActivityContext context)
        {
            bool readOnlyFlagValue = context.GetValue(ReadOnlyFlagValue);
            string[] filesToSet = context.GetValue(FilesToSet);
            foreach (string sFile in filesToSet)
            {
                var attributes = File.GetAttributes(sFile);
                if (readOnlyFlagValue)
                    File.SetAttributes(sFile, attributes | FileAttributes.ReadOnly);
                else File.SetAttributes(sFile, attributes & ~FileAttributes.ReadOnly);
            }
        }
      
        
    }
}