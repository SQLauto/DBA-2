using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Activities;
using System.Net;
using CustomBuildActivities.LabManagerService;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Build.Workflow.Activities;
using System.ServiceModel;

namespace LabManager
{
    /// <summary>
    /// Clone Configuration in Lab Manager
    /// </summary>
    [BuildActivity(HostEnvironmentOption.All)]
    public sealed class CloneConfiguration : CodeActivity<int>
    {
        // Define the activity arguments
        public InArgument<Details> ServerDetails { get; set; }
        public InArgument<string> TargetWorkspace { get; set; }
        public InArgument<string> SourceConfigurationName { get; set; }
        public InArgument<string> CloneConfigurationName { get; set; }

        protected override int Execute(CodeActivityContext context)
        {
            Details labManagerDetails = context.GetValue(this.ServerDetails);
            string sourceConfigName = context.GetValue(this.SourceConfigurationName);
            string cloneConfigName = context.GetValue(this.CloneConfigurationName);
            string targetWorkspaceName = context.GetValue(this.TargetWorkspace);
            
            Configuration sourceConfig;
            //Configuration targetConfig;
            int targetConfigID = 0;

            Service labManagerService = new Service(labManagerDetails);

            //set target workspace
            labManagerService.AuthHeader.workspacename = targetWorkspaceName;

            try
            {
                //find the source configuration
                sourceConfig = labManagerService.Client.GetConfigurationByName(labManagerService.AuthHeader, sourceConfigName).First();

                if (sourceConfig.type == 3) //only for gold
                {
                    targetConfigID = labManagerService.Client.ConfigurationCheckout(labManagerService.AuthHeader, sourceConfig.id, cloneConfigName);
                }

                return targetConfigID;

            }
            catch (Exception ex)
            {
                context.TrackBuildError(ex.Message);
                return 0;
            }

        }
    }
}