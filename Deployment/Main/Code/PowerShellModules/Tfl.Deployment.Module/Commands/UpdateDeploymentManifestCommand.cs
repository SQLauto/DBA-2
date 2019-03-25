using System.IO;
using System.Management.Automation;
using Deployment.Common.Xml;
using Deployment.Domain;
using Deployment.Domain.Operations.Services;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsData.Update, "DeploymentManifest")]
    [OutputType(typeof(DeploymentManifest))]
    public class UpdateDeploymentManifestCommand : PSCmdletBase
    {
        private string _path;

        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNullOrEmpty]
        public string Path
        {
            get { return _path; }
            set
            {
                _path = GetUnresolvedProviderPathFromPSPath(value);
            }
        }

        [Parameter(Mandatory = true)]
        [ValidateNotNull]
        public DeploymentManifest Manifest { get; set; }

        protected override void ProcessRecord()
        {
            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);

            var parent = Directory.GetParent(Path).FullName;

            var pathBuilder = new RootPathBuilder(parent, logger) { PackageDirectory = Path };

            logger.WriteLine($"Saving deployment manifest to {pathBuilder.PackageDirectory}");

            var deploymentManifestService = new DeploymentManifestService(pathBuilder, new XmlParserService(), logger);

            var deploymentManifest = deploymentManifestService.UpdateDeploymentManifest(Manifest);

            WriteObject(deploymentManifest);
        }
    }
}