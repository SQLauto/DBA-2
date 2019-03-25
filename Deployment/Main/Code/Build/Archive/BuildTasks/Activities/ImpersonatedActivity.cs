using System.Activities;
using CustomBuildActivities.CustomType;
using CustomBuildActivities.Library;
using Microsoft.TeamFoundation.Build.Client;

namespace CustomBuildActivities.Activities
{
    [BuildActivity(HostEnvironmentOption.Agent)]
    public class CopyFile : CodeActivity
    {

        public InArgument<Credential> Credentials { get; set; }

        protected override void Execute(CodeActivityContext context)
        {
            using (Impersonation impersonation = new Impersonation(context.GetValue(this.Credentials)))
            {
                // Insert your activity code over here
            }
        }
    }
}
