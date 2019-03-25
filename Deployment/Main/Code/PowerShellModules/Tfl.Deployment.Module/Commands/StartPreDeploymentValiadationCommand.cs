using System.Collections.Generic;
using System.Management.Automation;
using Deployment.Domain.Operations;
using Deployment.Domain.Operations.Services;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsLifecycle.Start, "PreDeploymentValidation")]
    [OutputType(typeof(bool))]
    public class StartPreDeploymentValiadationCommand : PSCmdletBase
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
        [PSDefaultValue(Value = @"D:\Deploy\Logs")]
        public string LogPath { get; set; }
        [Parameter]
        public IList<string> Groups { get; set; }
        [Parameter]
        public IList<string> Servers { get; set; }
        [Parameter]
        public SwitchParameter LocalDebug { get; set; }

        protected override void ProcessRecord()
        {
            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);

            var parameterService = new ParameterService(logger);

            var builder = string.IsNullOrWhiteSpace(BuildLocation) ? new RootPathBuilder(logger) : new RootPathBuilder(BuildLocation, logger)
            {
                IsLocalDebugMode = LocalDebug,
                OutputDirectory = LogPath
            };

            var parameters = new DeploymentOperationParameters
            {
                DeploymentConfigFileName = Configuration,
                DecryptionPassword = ServiceAccountsPassword,
                Groups = Groups ?? new List<string>(),
                Servers = Servers ?? new List<string>(),
            };

            var validator = new DeploymentValidation(parameterService, logger);
            var result = validator.PreDeploymentValidation(builder, parameters);

            WriteObject(result);
        }
    }
}