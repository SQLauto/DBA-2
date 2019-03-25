using System;
using System.Activities;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Diagnostics;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Build.Workflow.Tracking;
using Microsoft.TeamFoundation.VersionControl.Client;

namespace CustomBuildActivities.SQL
{
    /// <summary>
    /// Build Activity Wrapper for the VSDBCMD Command Line
    /// </summary>
    /// <example>
    /// vsdbcmd /a:Deploy /dsp:SQL /cs:"Data Source=10.107.203.8;User ID=build;Password=build" /manifest:"CSC SQL Server Schema.deploymanifest" /p:TargetDatabase="CSCTestDeployment" /dd /p:BuildVersion="TestForBuildVersion0.0.0.1"
    /// </example>
    [BuildActivity(HostEnvironmentOption.Agent)]
    public class VSDBCMD : CodeActivity
    {
       
        [RequiredArgument]
        public InArgument<string> ConnectionString { get; set; }
        
        [RequiredArgument]
        public InArgument<string> ManifestFile { get; set; }

        [RequiredArgument]
        public InArgument<string> TargetDatabase { get; set; }

        public InArgument<string> OptionalParameters { get; set; }
        
        public InArgument<string> OverrideParameters { get; set; }

        [RequiredArgument]
        public InArgument<bool> WaitForExit { get; set; }

        [RequiredArgument]
        public InArgument<string> VSDBCMDPathFilename { get; set; }


        protected override void Execute(CodeActivityContext context)
        {

            string options = " /a:Deploy /dsp:SQL /dd ";
            string exePathFilename = "";

            try
            {
                 exePathFilename = context.GetValue(VSDBCMDPathFilename);

                if (!System.IO.File.Exists(exePathFilename))
                {
                    TrackMessage(context, "RemoteExecute does not exists at: " + exePathFilename, BuildMessageImportance.Low);
                    ///return false;
                }

                
                options += string.Format(@" /cs:""{0}""", ConnectionString.Get(context));
                options += string.Format(@" /manifest:""{0}""", ManifestFile.Get(context));


                string optionalParameters = context.GetValue(OptionalParameters);

                if (optionalParameters != null && optionalParameters.Length > 0)
                {
                    options += " " + optionalParameters;
                }


                string overrideParameters = context.GetValue(OverrideParameters);

                if (overrideParameters != null && overrideParameters.Length > 0)
                {
                    options = overrideParameters;
                }


                
                Process p = Process.Start(exePathFilename, options);
                if (WaitForExit.Get(context))
                {
                    p.WaitForExit();

                    if (p.ExitCode != 0)
                    {
                        string message = "Executing " + exePathFilename + options + " returned code:" + p.ExitCode;
                        TrackMessage(context, message, BuildMessageImportance.High);
                    }
                }

                //return true;
            }
            catch (Exception ex)
            {
                if (true) //(BuildEngine != null)
                {
                    TrackMessage(context, "Error executing " + exePathFilename + options  + ":::" +
                                 ex, BuildMessageImportance.High);
                }
                //return false;
            }

        }

        protected void TrackMessage(CodeActivityContext context, string message, BuildMessageImportance importance)
        {

            context.Track(

                new BuildInformationRecord<BuildMessage>()

                {

                    Value = new BuildMessage() { Importance = importance, Message = message }

                });

        }  

    }
    public sealed class BuildMessage
    {
        public String Message { get; set; }
        public BuildMessageImportance Importance { get; set; }
    }

}
