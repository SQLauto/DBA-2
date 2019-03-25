using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Activities;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Build.Workflow.Activities;
using Microsoft.TeamFoundation.VersionControl.Client;
using CustomBuildActivities.Exceptions;
using Deployment.Utils;
using CustomBuildActivities.Helper;
namespace CustomBuildActivities.FileActivities
{
    [BuildActivity(HostEnvironmentOption.All)]
    public sealed class UpdateAppSettingRoot : CodeActivity
    {
        [RequiredArgument]
        public InArgument<string> ConfigFileName { get; set; }

        [RequiredArgument]
        public InArgument<string> OldConfigName { get; set; }

        [RequiredArgument]
        public InArgument<string> NewConfigName { get; set; }
        
        [RequiredArgument]
        public InArgument<string> ConfigValue { get; set; }

        [RequiredArgument]
        public InArgument<string> ConfigRoot{ get; set; }

        [RequiredArgument]
        public InArgument<Workspace> Workspace { get; set; }
        
        protected override void Execute(CodeActivityContext context)
        {
            string newConfigName = context.GetValue(NewConfigName);
            string oldConfigname = context.GetValue(OldConfigName);
            string configFileName = context.GetValue(ConfigFileName);
            string configValue = context.GetValue(ConfigValue);
            string configRoot= context.GetValue(ConfigRoot);
            Workspace workspace = context.GetValue(Workspace);

            //if (newConfigName.Length == 0 || configValue.ToString().Length == 0 || oldConfigname.Length==0|| configFileName.Length==0
            //    ||configRoot.Length==0||workspace.ToString().Length==0)
            //{
            //    throw new ActivityException(string.Format("There was an error with newConfigName, oldConfigname, configValue, configFileName, configRoot, workspace: {0}, {1}, {2}, {3}, {4}, {5}",
            //        newConfigName, oldConfigname, configValue, configFileName, configRoot, workspace.ToString()));
            //}

            UpdateAppSettingHelper helper = new UpdateAppSettingHelper();
            helper.UpdateAppSetting(workspace, configFileName, configRoot, oldConfigname, newConfigName, configValue,context);
            
        }
    }
}
