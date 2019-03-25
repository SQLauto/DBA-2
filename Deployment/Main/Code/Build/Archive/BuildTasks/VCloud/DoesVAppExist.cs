using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Activities;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Build.Workflow.Activities;
using System.ServiceModel;

namespace VCloud
{
    [BuildActivity(HostEnvironmentOption.All)]
    public sealed class DoesVAppExist : CodeActivity
    {
        // Define Activty Arguements
        public InArgument<string> RigName { get; set; }
        public OutArgument<Boolean> Result { get; set; }

        protected override void Execute(CodeActivityContext context)
        {
            bool verifiedVapp;
            try
            {
                // Create a vCloud connection
                VCloudService VCloudService = new VCloudService();

                // Try to verify if the vApp exists
                verifiedVapp = VCloudService.VerifyVapp(context.GetValue(this.RigName));
            }
            catch (Exception ex)
            {
                // Any failures push the error message to the build log and set return value to false.
                context.TrackBuildError(ex.Message);
                verifiedVapp = false;
            }

            context.SetValue(this.Result, verifiedVapp);
        }
    }
}
