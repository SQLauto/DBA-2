using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Activities;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.VersionControl.Client;

using Deployment.Utils;

namespace CustomBuildActivities.FileActivities
{
    [BuildActivity(HostEnvironmentOption.Agent)]
    public sealed class UpdateAppSettingWithRoot : CodeActivity
    {
        [RequiredArgument]
        public InArgument<string> FileName { get; set; }

        [RequiredArgument]
        public InArgument<string> Root { get; set; }
        
        [RequiredArgument]
        public InArgument<string> Name { get; set; }

        [RequiredArgument]
        public InArgument<string> Value { get; set; }

        protected override void Execute(CodeActivityContext context)
        {
            string name = context.GetValue(Name);
            string fileName = context.GetValue(FileName);
            string root= context.GetValue(Root);
            string value = context.GetValue(Value);

            DeploymentUtilities.UpdateAppSetting(fileName, root, name, value);
        }
    }
}
