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
    [BuildActivity(HostEnvironmentOption.All)]
    public sealed class MoveConfiguration : CodeActivity<int>
    {
        // Define the activity arguments
        public InArgument<Details> ServerDetails { get; set; }
        public InArgument<string> TargetWorkspace { get; set; }
        public InArgument<string> SourceConfigurationName { get; set; }
        public InArgument<string> TargetConfigurationName { get; set; }

        protected override int Execute(CodeActivityContext context)
        {
            Details labManagerDetails = context.GetValue(this.ServerDetails);
            string sourceConfigName = context.GetValue(this.SourceConfigurationName);
            string targetWorkspaceName = context.GetValue(this.TargetWorkspace);
            string targetConfigurationName = context.GetValue(this.TargetConfigurationName);
            
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
                context.TrackBuildMessage(string.Format("Found configuration {0} id={1}", sourceConfig.name, sourceConfig.id), BuildMessageImportance.Normal);

                //todo: config not found

                targetConfigID = labManagerService.Client.ConfigurationClone(labManagerService.AuthHeader, sourceConfig.id, targetConfigurationName);
                context.TrackBuildMessage(string.Format("Cloned configuration to {0} id={1}",  targetConfigurationName, targetConfigID), BuildMessageImportance.Normal);

                if (targetConfigID > 0)
                {
                    // Delete the original configuration
                    labManagerService.Client.ConfigurationDelete(labManagerService.AuthHeader, sourceConfig.id);
                    context.TrackBuildMessage(string.Format("Deleted original configuration id={1}", sourceConfig.id), BuildMessageImportance.Normal);
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