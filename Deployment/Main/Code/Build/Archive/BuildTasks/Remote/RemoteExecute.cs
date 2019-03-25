using System;
using System.Activities;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Diagnostics;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Build.Workflow.Tracking;
using Microsoft.TeamFoundation.VersionControl.Client;

namespace CustomBuildActivities.Remote
{
    [BuildActivity(HostEnvironmentOption.Agent)]
    public class RemoteExecute : CodeActivity
    {
        protected override void Execute(CodeActivityContext context)
        {
            string exeFilePath = "";
            try
            {
                exeFilePath = RemoteExecutePathFilename.Get(context);

                if (!System.IO.File.Exists(exeFilePath))
                {
                    TrackMessage(context, "RemoteExecute does not exists at: " + exeFilePath, BuildMessageImportance.Low);
                    
                    ///return false;
                }

                string options = " -i 0 -s -accepteula";
                string username = Username.Get(context);
                string password = Password.Get(context);

                if (username != null)
                {
                    options += " -u " + username;
                    if (password != null)
                    {
                        options += " -p " + password;
                    }
                }

                string overridepsexecargs = OverridePSExecArgs.Get(context);
                if (overridepsexecargs != null && overridepsexecargs.Length > 0)
                {
                    options = overridepsexecargs;
                }


                if (true) //(!waitForExit)
                    options += " -d ";

                string args = @"\\" + TargetMachine.Get(context) + options + RemoteCommand.Get(context) + " " + OptionalParameters.Get(context);



                Process p = Process.Start(exeFilePath, args);
                if (WaitForExit.Get(context))
                {
                    p.WaitForExit();

                    if (p.ExitCode != 0)
                    {
                        string message = "Executing " + RemoteCommand.Get(context) + " on " + TargetMachine.Get(context) + " returned code:" + p.ExitCode;

                        TrackMessage(context, message, BuildMessageImportance.High);
                    }
                }
                //return true;
            }
            catch (Exception ex)
            {
                if (true) //(BuildEngine != null)
                {
                    TrackMessage(context, "Error executing " + RemoteCommand.Get(context) + " TargetMachine=" +
                                 TargetMachine.Get(context) + " RemoteExecutePathFilename=" + exeFilePath + ":::" +
                                 ex, BuildMessageImportance.High);
                }
                //return false;
            }

        }

        [RequiredArgument]
        public InArgument<string> TargetMachine { get; set; }

        [RequiredArgument]
        public InArgument<string> RemoteCommand { get; set; }
        
        public InArgument<string> OptionalParameters { get; set; }
        
        public InArgument<string> Username { get; set; }
        public InArgument<string> Password { get; set; }

        [RequiredArgument]
        public InArgument<bool> WaitForExit { get; set; }

        [RequiredArgument]
        public InArgument<string> RemoteExecutePathFilename { get; set; }
        
        public InArgument<string> OverridePSExecArgs { get; set; }

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
