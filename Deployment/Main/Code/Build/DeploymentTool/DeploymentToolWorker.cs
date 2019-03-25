using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Deployment.Entities;
using Deployment.Logic.Entities;
using Deployment.Utils;
using Deployment.Utils.Enum;
using DeploymentTool.DeploymentToolTasks;

namespace DeploymentTool
{
    public class DeploymentToolWorker
    {
        private IDeploymentToolTask _deploymentToolTask;
        private DeploymentTaskParameters _taskParameters;
        private readonly IDictionary<DeploymentTaskType, Lazy<IDeploymentToolTask>> _taskFactory;

        public DeploymentToolWorker()
        {
            _taskFactory = new Dictionary<DeploymentTaskType, Lazy<IDeploymentToolTask>>
            {
                {DeploymentTaskType.Decrypt, new Lazy<IDeploymentToolTask>(()=>new DecryptDeploymentToolTask())},
                {DeploymentTaskType.Encrypt, new Lazy<IDeploymentToolTask>(()=>new EncryptDeploymentToolTask())},
                {DeploymentTaskType.Package, new Lazy<IDeploymentToolTask>(()=>new PackageDeploymentToolTask())},
                {DeploymentTaskType.PostDeployTest, new Lazy<IDeploymentToolTask>(()=>new PostDeploymentValidationToolTask())},
                {DeploymentTaskType.PostLabDeployTest, new Lazy<IDeploymentToolTask>(()=>new PostLabDeploymentValidationToolTask())},
                {DeploymentTaskType.PreDeployTest, new Lazy<IDeploymentToolTask>(()=>new PreDeploymentValidationToolTask())},
                {DeploymentTaskType.Preview, new Lazy<IDeploymentToolTask>(()=>new PreviewDeploymentToolTask())},
            };
        }

        public DeploymentTaskResult RunTask(string[] args)
        {
            var deploymentTaskResult = ValidateParameters(args);

            if (!deploymentTaskResult.Valid)
                return deploymentTaskResult;

            deploymentTaskResult = _deploymentToolTask.TaskWork(_taskParameters);

            return deploymentTaskResult;
        }

        private DeploymentTaskResult ValidateParameters(string[] args)
        {
            var commandLine = args.Aggregate(string.Empty, (current, arg) => current + (arg + " ")).TrimEnd();

            if (string.IsNullOrWhiteSpace(commandLine) || commandLine.Contains('?'))
            {
                return DeploymentTaskResult.False;
            }

            _taskParameters = ParseCommandLine(commandLine);

            _deploymentToolTask = GetDeploymentTask(_taskParameters.Type);

            return _deploymentToolTask == null
                ? new DeploymentTaskResult(false, "Deployment Type is invalid.")
                : _deploymentToolTask.InputParametersAreValid(_taskParameters);
        }

        private IDeploymentToolTask GetDeploymentTask(DeploymentTaskType deploymentTaskType)
        {
            if (_taskFactory == null || !_taskFactory.ContainsKey(deploymentTaskType))
                return null;

            return _taskFactory[deploymentTaskType].Value;
        }

        private DeploymentTaskParameters ParseCommandLine(string commandLine)
        {
            var builder = new PathBuilder
            {
                BuildLocation =
                    DeploymentUtilities.GetCommandLineParameterPathWithoutTrailingSlash(commandLine, "-BuildLocation"),
                ServiceAccountsFile = DeploymentUtilities.GetCommandLineParameter(commandLine, "-ServiceAccountsFile"),
                PackageFileName = DeploymentUtilities.GetCommandLineParameter(commandLine, "-PackageName"),
                OutputDir =
                    DeploymentUtilities.GetCommandLineParameterPathWithoutTrailingSlash(commandLine, "-OutputDir"),
                JumpFolderLocation =
                    DeploymentUtilities.GetCommandLineParameterPathWithoutTrailingSlash(commandLine,
                        "-JumpFolderLocation")
            };

            var configFile = DeploymentUtilities.GetCommandLineParameter(commandLine, "-ConfigFile");
            builder.ConfigFile = GetConfigFileFromBuildLocation(builder.BuildLocation, configFile);

            var groupsAsString = DeploymentUtilities.GetCommandLineParameter(commandLine, "-Groups");
            var deploymentType = DeploymentUtilities.GetCommandLineParameter(commandLine, "-Type");

            var taskParams = new DeploymentTaskParameters
            {
                Paths = builder,
                Type = ParseDeploymentType(deploymentType),
                RigName = DeploymentUtilities.GetCommandLineParameter(commandLine, "-RigName"),
                Password = DeploymentUtilities.GetCommandLineParameter(commandLine, "-Password"),
                Groups = DeploymentGroupHelper.GetGroupsFromString(groupsAsString),
                Partition = DeploymentUtilities.GetCommandLineParameter(commandLine, "-Partition")
            };

            return taskParams;
        }

        private DeploymentTaskType ParseDeploymentType(string deploymentType)
        {
            var deloymentTaskType = EnumHelper.GetEnumByDescription<DeploymentTaskType>(deploymentType);
            return deloymentTaskType;
        }

        private string GetConfigFileFromBuildLocation(string buildLocation, string configFile)
        {
            var configFileName = Path.GetFileName(configFile);
            var configFileFromBuildLocation = Path.Combine(buildLocation, "Deployment\\Scripts", configFileName);

            return configFileFromBuildLocation;

        }
    }
}