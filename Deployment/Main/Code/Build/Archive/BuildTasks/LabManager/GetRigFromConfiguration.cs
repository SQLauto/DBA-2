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
    public sealed class GetRigFromConfiguration : CodeActivity<CustomBuildActivities.Rig>
    {
        // Define the activity arguments
        public InArgument<Details> ServerDetails { get; set; }
        public InArgument<string> ConfigurationName { get; set; }
        public InArgument<string> ConfigurationID { get; set; }

        protected override CustomBuildActivities.Rig Execute(CodeActivityContext context)
        {
            Details labManagerDetails = context.GetValue(this.ServerDetails);
            string configName = context.GetValue(this.ConfigurationName);
            CustomBuildActivities.Rig sourceRig = new CustomBuildActivities.Rig();

            Configuration sourceConfig;
            Service labManagerService = new Service(labManagerDetails);

            try
            {
                //find the source configuration
                sourceConfig = labManagerService.Client.GetConfigurationByName(labManagerService.AuthHeader, configName).First();

                sourceRig.Name = sourceConfig.name;
                sourceRig.Available = sourceConfig.isDeployed;
                sourceRig.Boxes = (from m in labManagerService.Client.ListMachines(labManagerService.AuthHeader, sourceConfig.id)
                                      select new CustomBuildActivities.Box(m.name, m.internalIP, m.externalIP, SelectLayerFromName(m.name))
                                     ).ToList();
            }
            catch (Exception ex)
            {
                context.TrackBuildError(ex.Message);
            }

            return sourceRig;
        }

        private string SelectLayerFromName(string machineName)
        {
            if (machineName.Contains("App"))
            {
                return "Application";
            }
            else if (machineName.Contains("DB"))
            {
                return "Database";
            }
            else if (machineName.Contains("Pres"))
            {
                return "Presentation";
            }
            else
            {
                return "General";
            }
        }
    }
}