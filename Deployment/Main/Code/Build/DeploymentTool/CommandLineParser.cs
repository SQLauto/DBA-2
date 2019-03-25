using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Deployment.Common;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Common.Settings;
using Deployment.Domain.Operations;
using Deployment.Domain.Operations.Services;

namespace Deployment.Tool
{
    public class CommandLineParser : ICommandLineParser
    {
        //TODO: Make this dictionary non-case sensitive
        private readonly IDictionary<string, string> _arguments;
        private readonly IDeploymentLogger _logger;

        public CommandLineParser()
        {
            _arguments = new Dictionary<string, string>();
            _logger = new ConsoleLogger();
        }

        public DeploymentOperationParameters Parse(IList<string> args)
        {
            _logger.WriteLine("Parsing CommandLine parameters:");

            if (args.Count == 0)
                return null;

            //depending upon how passed, command could be just a string, so split it
            if (args.Count == 1)
            {
                _logger.WriteLine("A single parameter was passed in. Determine if it is a string we need to split.");
                args = args[0].Split(' ');
            }

            if (args.Count == 1)
            {
                _logger.WriteError("No usages of the tool take a single parameter, yet only one was passed.");
                return null;
            }

            for (var i = 0; i < args.Count; i++)
            {
                if (!args[i].StartsWith("-"))
                    continue;

                //determine if we have boolean style parameter (ie. arg only)
                var result = ParseBoolArgument(args[i]);

                if (result)
                {
                    _arguments.Add(args[i], "true");
                    continue;
                }

                var key = args[i];
                var val = args[i + 1];

                _arguments.Add(key, val.Replace("'", ""));
            }

            return GetParameters();
        }

        private DeploymentOperationParameters GetParameters()
        {
            var taskParams = new DeploymentOperationParameters
            {
                Password = GetStringArgument("-Password"),
                TaskType = ParseTypeArgument(GetStringArgument("-Type")),
                RigName = GetStringArgument("-RigName"),
                PackageDeploymentAccount = GetStringArgument("-DeploymentAccount"),
                Groups = GetListArgument("-Groups"),
                Servers = GetListArgument("-Servers"),
                IsDatabaseDeployment = GetBoolArgument("-IsDbDeployment"),
                DeploymentConfigFileName = GetStringArgument("-ConfigFile"),
                PackageFileName = GetStringArgument("-PackageName"),
                ServiceAccountsFile = GetStringArgument("-ServiceAccountsFile"),
                IsLocalDebugMode = GetBoolArgument("-LocalDebugMode"),
                BuildLocation = GetPathArgument("-BuildLocation"),
                OutputDirectory = GetPathArgument("-OutputDir"),
                DriveLetter = GetStringArgument("-DriveLetter")
            };

            if (string.IsNullOrWhiteSpace(taskParams.DriveLetter))
            {
                taskParams.DriveLetter = "D";
            }
            if (!string.IsNullOrWhiteSpace(taskParams.RigName))
            {
                taskParams.Platform = DeploymentPlatform.VCloud;

                taskParams.Username = AppSettings.VirtualPlatform.vCloudDomain + @"\" +
                                      AppSettings.VirtualPlatform.vCloudDomainUserName;

                taskParams.Password = AppSettings.VirtualPlatform.vCloudDomainPassword;

                taskParams.DecryptionPassword = AppSettings.ServiceAccountsPassword;
            }

            return taskParams;
        }

        public string GetHelp()
        {
            var builder = new StringBuilder("We expect command line in form");

            builder.AppendLine(
                @"'-Type Pre/Post/PostLab/Encrypt/Decrypt/Package/Preview' -ConfigFile 'c:\text.xml' -ServiceAccountsFile 'd:\file.xml' -BuildLocation 'c:\Binaries' -RigName 'MyRig' -Password 'pa$$word' -PackageName '[optional path]package.zip' -IsDbDeployment -ManifestPath 'D:\YourPath\'");

            var help =
                @"-Type Pre
    Perform predeployment validation.
    Requires: -ConfigFile,  -BuildLocation, -Groups (optional comma separated list), -Servers (optional comma separated list), -LocalDebugMode (optional; use true when running in Visual Studio against source)
 Post
    Perform post deployment validation against a config file
    Requires: -ConfigFile, -Groups (optional comma separated list), -Servers (optional comma separated list) and -Password (optional)
PostLab
    Perform post deployment validation on a virtual rig against a config file
    Requires: -ConfigFile, -RigName, -Groups (optional comma separated list), -Servers (optional comma separated list), -Password (optional) and -Password (optional), -BuildLocation (optional when locally debugging from source) -LocalDebugMode (optional; flag set when running in Visual Studio against source)
Encrypt
    Encrypt a service accounts file using the given password
    Requires: -ServiceAccountsFile and -Password 
Decrypt
    Decrypt a service accounts file using the given password
    Requires: -ServiceAccountsFile and -Password
Preview
    Preview will generate a copy of the application and web configs for the given package
    Requires -ConfigFile, -PackageName and -OutputDir
Package
    Package a deployment into the specified archive. Archive will be created in the BuildLocation
    Requires: -ConfigFile, -BuildLocation, -PackageName, -Groups (optional comma separated list), -Servers (optional comma separated list), -DeploymentAccount (optional lookup name for the deployment account), -ManifestPath (optional if overriding default DeploymentManifest file path [Path only]), -IsDbDeployment (optional flag if package is a db only deployment)
    Package will be output in the -BuildLocation folder
";

            builder.AppendLine(help);

            return builder.ToString();
        }

        private DeploymentTaskType ParseTypeArgument(string value)
        {
            var result = EnumHelper.TryParse<DeploymentTaskType>(value);

            return result.Item1 ? result.Item2 : DeploymentTaskType.None;
        }

        private bool ParseBoolArgument(string argument)
        {
            // ReSharper disable once SwitchStatementMissingSomeCases
            switch (argument.ToLowerInvariant())
            {
                case "-localdebugmode":
                case "-isdbdeployment":
                    return true;
            }

            return false;
        }

        private string GetPathArgument(string argument)
        {
            //todo: get training slash etc.
            var val = _arguments.ContainsKey(argument) ? _arguments[argument] : null;
            return val;
        }

        private string GetStringArgument(string argument, string defaultValue = null)
        {
            return _arguments.ContainsKey(argument) ? _arguments[argument] : defaultValue;
        }

        private bool GetBoolArgument(string argument)
        {
            var boolString = _arguments.ContainsKey(argument) ? _arguments[argument] : "false";
            bool result;

            return bool.TryParse(boolString, out result) && result;
        }

        private IList<string> GetListArgument(string argument)
        {
            var val = _arguments.ContainsKey(argument) ? _arguments[argument] : null;
            return GetGroupsFromString(val);
        }

        private IList<string> GetGroupsFromString(string groups)
        {
            var result = new List<string>();
            if (string.IsNullOrWhiteSpace(groups))
                return result;

            var groupsAsArray = groups.Split(",".ToCharArray());
            result = (from g in groupsAsArray select g.Trim()).ToList();

            return result;
        }
    }
}