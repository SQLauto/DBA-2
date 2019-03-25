using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Activities;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.VersionControl.Client;
using Deployment.Utils;

namespace CustomBuildActivities.Activities
{
    /// <summary>
    /// Extract the parameter value from the given command line
    /// We expect the command line in the format -parameterName 'paramaterValue'
    /// </summary>
    [BuildActivity(HostEnvironmentOption.Agent)]
    public sealed class GetCommandLineParameter : CodeActivity<string>
    {
        [RequiredArgument]
        public InArgument<string> CommandLine { get; set; }

        [RequiredArgument]
        public InArgument<string> ParameterName { get; set; }

        protected override string Execute(CodeActivityContext context)
        {
            string commandLine = context.GetValue(CommandLine);
            string parameterName = context.GetValue(ParameterName);
            return DeploymentUtilities.GetCommandLineParameter(commandLine, parameterName);
        }
    }
}

