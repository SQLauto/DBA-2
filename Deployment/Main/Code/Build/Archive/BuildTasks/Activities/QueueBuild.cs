using System;
using System.Activities;
using System.Diagnostics;
using System.IO;
using System.Text.RegularExpressions;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Client;
using Microsoft.TeamFoundation.Framework.Client;
using Microsoft.TeamFoundation.VersionControl.Client;

namespace CustomBuildActivities.Activities
{
    [BuildActivity(HostEnvironmentOption.Agent)]
    public sealed class QueueBuild : CodeActivity
    {
        /// <summary>
        /// The url for the TFS Server
        /// </summary>
        [RequiredArgument]
        public InArgument<string> TFSUrl { get; set; }


        /// <summary>
        /// The project of the TFS collection
        /// </summary>
        [RequiredArgument]
        public InArgument<string> ProjectName { get; set; }

        /// <summary>
        /// This will be the build we want the latest version to get from
        /// </summary>
        [RequiredArgument]
        public InArgument<string> BuildDefinitionName { get; set; }



        protected override void Execute(CodeActivityContext context)
        {

            string tfsUrl = context.GetValue(TFSUrl);
            string projectName = context.GetValue(ProjectName);
            string buildDefinitionName = context.GetValue(BuildDefinitionName);

            var tfsUri = new Uri(tfsUrl);
            var teamProjectCollection = Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory.GetTeamProjectCollection(tfsUri);
            IBuildServer buildServer= teamProjectCollection.GetService<IBuildServer>();

            IBuildDefinition buildDef = buildServer.GetBuildDefinition(projectName, buildDefinitionName);
            buildServer.QueueBuild(buildDef);

        }
    }
}
