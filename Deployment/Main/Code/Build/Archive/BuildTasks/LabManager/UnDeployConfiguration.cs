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
    public sealed class UnDeployConfiguration : CodeActivity<Boolean>
    {
        // Define the activity arguments
        public InArgument<Details> ServerDetails { get; set; }
        public InArgument<string> ConfigurationName { get; set; }
        public InArgument<int> ConfigurationID { get; set; }

        protected override bool Execute(CodeActivityContext context)
        {
            Details labManagerDetails = context.GetValue(this.ServerDetails);
            string targetConfigurationName = context.GetValue(this.ConfigurationName);
            int targetConfigID = context.GetValue(this.ConfigurationID);
            
            Configuration targetConfig;
            Service labManagerService = new Service(labManagerDetails);
            

            try
            {
                if (targetConfigID > 0)
                { 
                }
                else
                {
                    //find the configuration
                    targetConfig = labManagerService.Client.GetConfigurationByName(labManagerService.AuthHeader, targetConfigurationName).First();
                    context.TrackBuildMessage(string.Format("Found configuration {0} id={1}", targetConfig.name, targetConfig.id), BuildMessageImportance.Normal);
                    targetConfigID = targetConfig.id;
                }

                if (targetConfigID > 0)
                {
                    // ShutDown configuration
                    labManagerService.Client.ConfigurationUndeploy(labManagerService.AuthHeader, targetConfigID ); // 8 = shutdown
                    context.TrackBuildMessage(string.Format("UnDeploy configuration id={0}", targetConfigID), BuildMessageImportance.Normal);
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