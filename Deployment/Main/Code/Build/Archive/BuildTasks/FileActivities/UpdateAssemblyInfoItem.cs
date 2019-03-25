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
    public sealed class UpdateAssemblyInfoItem : CodeActivity
    {
        [RequiredArgument]
        public InArgument<string[]> FilesToUpdate{ get; set; }
        [RequiredArgument]
        public InArgument<string> AssemblyInfoItemToUpdate{ get; set; }
        [RequiredArgument]
        public InArgument<string> AssemblyInfoValue { get; set; }
        protected override void Execute(CodeActivityContext context)
        {

            string[] filesToUpdate = context.GetValue(FilesToUpdate);
            string assemblyInfoItemToUpdate = context.GetValue(AssemblyInfoItemToUpdate);
            bool changedContents;
            foreach (string sfileToUpate in filesToUpdate)
            {
                var text = File.ReadAllText(sfileToUpate);
                changedContents = false;

                foreach (var attribute in new[] { assemblyInfoItemToUpdate })
                {
                    var regex = new Regex(attribute + @"\("".*""\)"); //everything between the quotes
                    var match = regex.Match(text);
                    if (!match.Success) continue;
                    text = regex.Replace(text, attribute + "(\"" + context.GetValue(AssemblyInfoValue) + "\")");
                    changedContents = true;
                }
                if (changedContents) File.WriteAllText(sfileToUpate, text);
            }
        }
    }
}
