using System.Activities;
using System.IO;
using System.Collections;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.VersionControl.Client;

namespace CustomBuildActivities.FileActivities
{
    [BuildActivity(HostEnvironmentOption.Agent)]
    public sealed class LogToFile : CodeActivity
    {
        [RequiredArgument]
        public InArgument<string> FileName { get; set; }
        
        [RequiredArgument]
        public InArgument<bool> Append { get; set; }

        [RequiredArgument]
        public InArgument<string> StringData{ get; set; }

        protected override void Execute(CodeActivityContext context)
        {
            bool appendFlag = context.GetValue(Append);
            string fileName = context.GetValue(FileName);
            string stringData = context.GetValue(StringData);

            using (StreamWriter outfile = new StreamWriter(fileName, appendFlag))
            {
                outfile.WriteLine(stringData);
            }
        }        
    }
}