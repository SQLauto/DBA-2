using System;
using System.Activities;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Build.Workflow.Activities;
using Microsoft.TeamFoundation.VersionControl.Client;
using Microsoft.TeamFoundation.Client;
using CustomBuildActivities.Exceptions;

namespace CustomBuildActivities.Activities
{
    /// <summary>
    /// Build Workflow activity to check if a file exists in source control
    /// </summary>
    [BuildActivity(HostEnvironmentOption.All)]
    public sealed class CheckFileExistsinSource : CodeActivity
    {
        // Define Activity Arguments
        /// <summary>
        /// The TFS Url so we can connect to the relevant source control
        /// </summary>
        [RequiredArgument]
        public InArgument<string> TFSUrl { get; set; }
        
        /// <summary>
        /// The source path of the file we want to check exists
        /// </summary>
        [RequiredArgument]
        public InArgument<List<string>> FileSourcePaths { get; set; }
        
        /// <summary>
        /// The result being passed out to the Build Workflow
        /// </summary>
        [RequiredArgument]
        public OutArgument<Boolean> FileExists { get; set; }
        
        // Define Activty Execution
        protected override void Execute(CodeActivityContext context)
        {
            bool fileExists = true;
            bool verified = false;

            try
            {
                // Getting the TFS URL, Connecting to the Project Collection and Accessing Version Control
                Uri TfsUri = new Uri(context.GetValue(this.TFSUrl));
                TfsTeamProjectCollection tpc = new TfsTeamProjectCollection(TfsUri);
                VersionControlServer vcs = tpc.GetService<VersionControlServer>();

                // Check File Exists
                foreach (string fileSourcePath in context.GetValue(this.FileSourcePaths))
                {
                    verified = vcs.ServerItemExists(fileSourcePath, VersionSpec.Latest, DeletedState.NonDeleted, ItemType.File);
                    if (!verified)
                    {
                        context.TrackBuildError(string.Format("File {0} could not be found in source control", fileSourcePath));
                        fileExists = false;
                    }
                }


            }
            catch(Exception ex)
            {
                // On Error pump error message into build log
                context.TrackBuildError(ex.Message);
                fileExists = false;
            }
            
            // Return value for build.
            context.SetValue(this.FileExists, fileExists);
        }
    }
}
