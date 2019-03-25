using System;
using System.Activities;
using System.Diagnostics;
using System.IO;
using System.Text.RegularExpressions;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Client;
using Microsoft.TeamFoundation.Framework.Client;
using Microsoft.TeamFoundation.VersionControl.Client;
using CustomBuildActivities.Exceptions;

namespace CustomBuildActivities.Activities
{
    [BuildActivity(HostEnvironmentOption.Agent)]
    public sealed class GetLastTenSuccessfulBuild : CodeActivity
    {
        /// <summary>
        /// The url for the TFS Server
        /// </summary>
        [RequiredArgument]
        public InArgument<string> TFSUrl{ get; set; }

        /// <summary>
        /// The project of the TFS collection
        /// </summary>
        [RequiredArgument]
        public InArgument<string> ProjectName{get;set;}

        /// <summary>
        /// This will be the build we want the latest version to get from
        /// </summary>
        [RequiredArgument]
        public InArgument<string> BuildDefinitionName { get; set; }

        /// <summary>
        /// This is the build number we are after to get last successful build
        /// </summary>
        [RequiredArgument]
        public OutArgument<string> LastSuccessfulBuildNumber { get; set; }


        /// <summary>
        /// This is the build number we are after to get last successful build
        /// </summary>
        [RequiredArgument]
        public OutArgument<String> LastSuccessfulBuildDropLocation { get; set; }


        protected override void Execute(CodeActivityContext context)
        {

            string tfsUrl = context.GetValue(@TFSUrl);
            string projectName = context.GetValue(ProjectName);
            string buildDefinitionName = context.GetValue(BuildDefinitionName);

            try
            {
                var tfsUri = new Uri(tfsUrl);
                var teamProjectCollection = Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory.GetTeamProjectCollection(tfsUri);
                IBuildServer service = teamProjectCollection.GetService<IBuildServer>();

                var spec = service.CreateBuildDetailSpec(projectName, buildDefinitionName);
                spec.MaxBuildsPerDefinition = 1;
                spec.QueryOrder = Microsoft.TeamFoundation.Build.Client.BuildQueryOrder.FinishTimeDescending;
                spec.Status = Microsoft.TeamFoundation.Build.Client.BuildStatus.Succeeded;
                var results = service.QueryBuilds(spec);
                if (results.Builds.Length >= 1)
                {
                    context.SetValue(LastSuccessfulBuildNumber, results.Builds[0].BuildNumber);
                    context.SetValue(LastSuccessfulBuildDropLocation, results.Builds[0].DropLocation);

                    //context.SetValue(LastSuccessfulBuild, results.Builds[0]);

                }
                else
                {
                    throw new Exception("No builds found.");
                }

            }
            catch (Exception ex)
            {
                throw new ActivityException("There is a problen with Get Last successfull build", ex);
            }


        }

    }
}
