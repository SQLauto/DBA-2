using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Activities;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.VersionControl.Client;
using CustomBuildActivities.Exceptions;
using Deployment.Utils;

namespace CustomBuildActivities.FileActivities
{
    [BuildActivity(HostEnvironmentOption.Agent)]
    public sealed class GetAppSetting : CodeActivity
    {
        [RequiredArgument]
        public InArgument<string> FileName { get; set; }

        [RequiredArgument]
        public InArgument<string> ConfigName { get; set; }

        [RequiredArgument]
        public InArgument<string> ConfigRoot { get; set; }

        [RequiredArgument]
        public OutArgument<string> ConfigValue { get; set; }

        protected override void Execute(CodeActivityContext context)
        {
            
            try
            {
                var configName = context.GetValue(ConfigName);
                var fileName = context.GetValue(FileName);
                var configRoot = context.GetValue(ConfigRoot);
                if(configName.Length==0 || configRoot.Length==0 || fileName.Length==0)
                {
                    throw new ActivityException(string.Format("There was an error with first 3 param: {0}, {1},{2}",configName,configRoot,fileName));
                }
                var configValue=DeploymentUtilities.GetAppSetting(fileName, configRoot, configName);
                context.SetValue(ConfigValue, configValue);
                if(ConfigValue.ToString().Length==0)
                {
                    throw new ActivityException(string.Format("There was an error with configValue: {0}", ConfigValue));
                }
            }
            catch (Exception ex)
            {
                throw new Exception("There was an error in execution of GetAppSetting",ex);
            }

        }
    }
}
