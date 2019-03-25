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
    public sealed class DoesVAppTemplateExist : CodeActivity
    {
        // Define Activity Arguements
        public InArgument<string> TemplateName { get; set; }
        public OutArgument<Boolean> Result { get; set; }

        protected override void Execute(CodeActivityContext context)
        {
            bool verifiedTemplate;

            try
            {
                VCloudService VCloudService = new VCloudService();
                verifiedTemplate = VCloudService.VerifyVappTemplate(context.GetValue(this.TemplateName));
            }
            catch(Exception ex)
            {
                context.TrackBuildError(ex.Message);
                verifiedTemplate = false;
            }

            Result.Set(context, verifiedTemplate);
        }
    }
}
