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
    public sealed class ShutDownConfiguration : CodeActivity<Boolean>
    {
        // Define the activity arguments
        public InArgument<Details> ServerDetails { get; set; }
        public InArgument<string> ConfigurationName { get; set; }

        protected override bool Execute(CodeActivityContext context)
        {
            Details labManagerDetails = context.GetValue(this.ServerDetails);
            string targetConfigurationName = context.GetValue(this.ConfigurationName);
            
            Configuration targetConfig;
            int targetConfigID = 0;

            Service labManagerService = new Service(labManagerDetails);
            

            try
            {
                //find the configuration
                targetConfig = labManagerService.Client.GetConfigurationByName(labManagerService.AuthHeader, targetConfigurationName).First();
                context.TrackBuildMessage(string.Format("Found configuration {0} id={1}", targetConfig.name, targetConfig.id), BuildMessageImportance.Normal);



                if (targetConfigID > 0)
                {
                    // ShutDown configuration
                    labManagerService.Client.ConfigurationPerformAction(labManagerService.AuthHeader, targetConfig.id, 8 ); // 8 = shutdown
                    context.TrackBuildMessage(string.Format("Shutdown configuration id={1}", targetConfig.id), BuildMessageImportance.Normal);
                }

                return true;

            }
            catch (Exception ex)
            {
                context.TrackBuildError(ex.Message);
                return false;
            }

        }
    }
}