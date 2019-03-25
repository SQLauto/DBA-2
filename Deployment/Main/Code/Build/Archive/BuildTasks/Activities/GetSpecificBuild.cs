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
    public sealed class GetSpecificBuild : CodeActivity
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
        public InArgument<string> SpecificBuildNumber { get; set; }


        /// <summary>
        /// This is the build number we are after to get last successful build
        /// </summary>
        [RequiredArgument]
        public OutArgument<IBuildDetail> SpecificBuild { get; set; }


        protected override void Execute(CodeActivityContext context)
        {

            string tfsUrl = context.GetValue(@TFSUrl);
            string projectName = context.GetValue(ProjectName);
            string buildDefinitionName = context.GetValue(BuildDefinitionName);
            string specificBuildNumber = context.GetValue(SpecificBuildNumber);
            var tfsUri = new Uri(tfsUrl);
            var teamProjectCollection = Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory.GetTeamProjectCollection(tfsUri);
            IBuildServer service = teamProjectCollection.GetService<IBuildServer>();

            var spec = service.CreateBuildDetailSpec(projectName, buildDefinitionName);
            spec.BuildNumber = specificBuildNumber;
            spec.MaxBuildsPerDefinition = 1;
            var results = service.QueryBuilds(spec);
            if (results.Builds.Length >= 1)
            {
                if (results.Builds[0].Status == BuildStatus.Succeeded || results.Builds[0].Status == BuildStatus.PartiallySucceeded)
                {
                    context.SetValue(SpecificBuild, results.Builds[0]);
                }
                else
                {
                    throw new Exception(string.Format("The build is not eligible as its status is not Succeded or PartiallySucceeded. The build {0} is {1}", specificBuildNumber, results.Builds[0].Status));
                }

            }
            else
            {
                throw new Exception(string.Format("No builds found for the specified build: {0} in team project {1} with buildName {2}", specificBuildNumber, projectName, buildDefinitionName));
            }
        }
    }
}
