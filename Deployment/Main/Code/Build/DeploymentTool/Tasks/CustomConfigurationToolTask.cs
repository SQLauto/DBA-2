using System;
using System.Text;
using Deployment.Logic.CustomConfig;
using Deployment.Logic.Validation;
using Deployment.Utils;

namespace DeploymentTool.DeploymentToolTasks
{
    public class CustomEnvironmentConfigurationToolTask : IDeploymentToolTask
    {
        public string TaskConsoleParameterName { get { return "customconfig"; } }

        public bool InputParametersAreValid(DeploymentTaskParameters taskParameters)
        {
            if (string.IsNullOrEmpty(taskParameters.Paths.ConfigFile))
            {
                Console.Out.WriteLine("Must supply a valid Custom config file name for post deployment validation [-ConfigFile]");
                return false;
            }

            return true;
        }

        public bool TaskWork(DeploymentTaskParameters taskParameters)
        {
            var ilog = new Logging(taskParameters.Paths.LoggingDirectoryPost, taskParameters.Paths.LoggingDirectoryPost, true, false);

            Console.Out.WriteLine(string.Format("Performing Custom Environment Configuration for config file '{0}'\r\n", taskParameters.Paths.ConfigFile));

            bool success = CustomEnvironmentConfiguration.ApplyCustomConfig(taskParameters.Paths, taskParameters.Paths.ConfigFile, taskParameters.Groups, ref ilog);

            var failedTests = ilog.LogResults.FindAll(x => x.TestResults.Equals(false));
            var failedConfigurationsDescription = new StringBuilder();
            int failedConfigurationsCount = 1;
            if (failedTests.Count > 0)
            {
                failedConfigurationsDescription.AppendLine("Summary of Roles failing Custom Environment Configuration:");
                foreach (LoggingResult failedTest in failedTests)
                {
                    failedConfigurationsDescription.AppendLine(string.Format("\t{0}. {1}", failedConfigurationsCount.ToString(), failedTest.TestName));
                    failedConfigurationsCount++;
                }

                failedConfigurationsDescription.AppendLine(string.Format("Validation Failed for {0} out of {1} Configurations", failedTests.Count, ilog.LogResults.Count));
            }
            ilog.LogAll("");
            if (success)
            {
                ilog.LogAll("Custom Environment Configuration Complete");
            }
            else
            {
                ilog.LogAll(failedConfigurationsDescription.ToString());
            }

            return success;
        }
    }
}