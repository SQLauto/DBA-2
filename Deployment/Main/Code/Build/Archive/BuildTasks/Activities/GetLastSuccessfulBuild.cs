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
    [BuildActivity(HostEnvironmentOption.All)]
    public sealed class GetLastSuccessfulBuild : CodeActivity
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
            bool foundBuild = false;

            var tfsUri = new Uri(tfsUrl);
            var teamProjectCollection = Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory.GetTeamProjectCollection(tfsUri);
            IBuildServer service = teamProjectCollection.GetService<IBuildServer>();

            var spec = service.CreateBuildDetailSpec(projectName, buildDefinitionName);
            spec.QueryOrder = Microsoft.TeamFoundation.Build.Client.BuildQueryOrder.FinishTimeDescending;
            var results = service.QueryBuilds(spec);
            if(results.Builds.Length == 0)
                throw new Exception(string.Format("No builds found in team project {0} with buildName {1}",projectName, buildDefinitionName));

            foreach(IBuildDetail Build in results.Builds)
            {
                if(Build.Status == BuildStatus.Succeeded || results.Builds[0].Status == BuildStatus.PartiallySucceeded)
                {
                    if(string.IsNullOrEmpty(Build.DropLocation))
                    {
                        throw new Exception("Drop location is not specified. Check if the build definition was set true for Copy to Output Folder parameter...");
                    }
                    else
                    {
                        context.SetValue(LastSuccessfulBuildNumber, Build.BuildNumber);
                        context.SetValue(LastSuccessfulBuildDropLocation, Build.DropLocation);
                        foundBuild = true;
                        break;
                    }
                }
            }
        
            if(!foundBuild)
            {
                throw new Exception(string.Format("No successful builds found in team project {0} with buildName {1}", projectName, buildDefinitionName));
            }
        }
    }
}
