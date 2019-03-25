using System.Collections.Generic;
using System.Management.Automation;
using Deployment.Common;
using Deployment.Domain.Operations;
using Deployment.Domain.Operations.Services;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsLifecycle.Start, "PostDeploymentValidation")]
    [OutputType(typeof(bool))]
    public class StartPostDeploymentValidationCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNullOrEmpty]
        [Alias("Config")]
        public string Configuration { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string ServiceAccountsPassword { get; set; }
        [Parameter]
        public string BuildLocation { get; set; }
        [Parameter]
        public string RigName { get; set; }
        [Parameter]
        public string DriveLetter { get; set; }
        [Parameter]
        public string LogPath { get; set; }
        [Parameter]
        public IList<string> Groups { get; set; }
        [Parameter]
        [Alias("Machines")]
        public IList<string> Servers { get; set; }
        [Parameter]
        public PSCredential Credential { get; set; }
        [Parameter]
        public SwitchParameter LocalDebug { get; set; }
        [Parameter]
        public SwitchParameter RemoveMappings { get; set; }
        [Parameter]
        public string EnvironmentType { get; set; }

        protected override void ProcessRecord()
        {
            if (string.IsNullOrEmpty(LogPath))
            {
                LogPath = $@"{DriveLetter}:\Deploy\Logs";
            }

            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);

            var parameterService = new ParameterService(logger);

            var builder = string.IsNullOrWhiteSpace(BuildLocation) ? new RootPathBuilder(@"D:\Deploy\DropFolder") : new RootPathBuilder(BuildLocation)
            {
                IsLocalDebugMode = LocalDebug,
                OutputDirectory = LogPath
            };

            var parameters = new DeploymentOperationParameters
            {
                Groups = Groups ?? new List<string>(),
                Servers = Servers ?? new List<string>(),
                DecryptionPassword = ServiceAccountsPassword,
                DeploymentConfigFileName = Configuration,
                DriveLetter = DriveLetter,
                Username = Credential.UserName,
                Password = Credential.GetNetworkCredential().Password
            };

            switch (EnvironmentType)
            {
                case "VCloud":
                    parameters.Platform = DeploymentPlatform.VCloud;
                    parameters.RigName = RigName;
                    break;
                case "Azure":
                    parameters.Platform = DeploymentPlatform.Azure;
                    parameters.RigName = RigName;
                    break;
                default:
                    parameters.Platform = DeploymentPlatform.CurrentDomain;
                    break;
            }

            var validator = new DeploymentValidation(parameterService, logger);
            var result = validator.PostDeploymentValidation(builder, parameters);

            WriteObject(result);
        }
    }
}