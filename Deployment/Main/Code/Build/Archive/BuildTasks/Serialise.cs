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

namespace CustomBuildActivities.Activities
{

    [BuildActivity(HostEnvironmentOption.All)]
    public sealed class Serialise : CodeActivity
    {
        // Define the activity arguments of type string
        public InArgument<string> Path { get; set; }
        public InArgument<Object> ObjectToSerialise { get; set; }

        // If your activity returns a value, derive from CodeActivity<TResult>
        // and return the value from the Execute method.
        protected override void Execute(CodeActivityContext context)
        {
            try
            {

            }
            catch (Exception ex)
            {
                context.TrackBuildError(ex.Message + ":" + ex.StackTrace);
            }

        }



    }
}