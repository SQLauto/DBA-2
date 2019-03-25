using System.Collections.Generic;
using System.Management.Automation;
using Deployment.Common.Xml;
using Deployment.Domain.Operations;
using Deployment.Domain.Operations.Services;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsLifecycle.Start, "PackageDeployment")]
    [OutputType(typeof(bool))]
    public class StartPackageDeploymentCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNullOrEmpty]
        [Alias("Config", "DeploymentConfig")]
        public string Configuration { get; set; }
        [Parameter]
        public string DeploymentAccount { get; set; }
        [Parameter]
        public string ServiceAccountsPassword { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string PackageName { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string BuildLocation { get; set; }
        [Parameter]
        public IList<string> Groups { get; set; }
        [Parameter]
        [Alias("Machines")]
        public IList<string> Servers { get; set; }

        [Parameter]
        public SwitchParameter IsDatabaseDeployment { get; set; }
        [Parameter]
        public SwitchParameter LocalDebug { get; set; }

        protected override void ProcessRecord()
        {
            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);

            var parameterService = new ParameterService(logger);

            var builder = new RootPathBuilder(BuildLocation, logger);
            builder.PackageDirectory = System.IO.Path.Combine(builder.RootDirectory, "Packages");
            var builders = builder.CreateChildPathBuilders(Configuration);

            var parameters = new DeploymentOperationParameters
            {
                IsLocalDebugMode = LocalDebug,
                DeploymentConfigFileName = Configuration,
                PackageFileName = PackageName,
                DecryptionPassword = ServiceAccountsPassword,
                Groups = Groups ?? new List<string>(),
                Servers = Servers ?? new List<string>(),
                PackageDeploymentAccount = DeploymentAccount,
                IsDatabaseDeployment = IsDatabaseDeployment
            };

            var domainOperatorFactory = new DomainOperatorFactory(parameterService, logger);
            var deploymentManifestService = new DeploymentManifestService(builder, new XmlParserService(), logger);
            var packagingService = new PackagingService(builder, builders, deploymentManifestService, parameterService, logger);

            var result = packagingService.CreateDeploymentPackage(domainOperatorFactory, parameters);

            WriteObject(result);
        }
    }
}