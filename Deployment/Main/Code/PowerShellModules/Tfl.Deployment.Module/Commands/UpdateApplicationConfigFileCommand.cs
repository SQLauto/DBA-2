using System;
using System.IO;
using System.Management.Automation;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Parameters;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsData.Update, "ApplicationConfigFile")]
    [OutputType(typeof(bool))]
    public class UpdateApplicationConfigFileCommand : PSCmdletBase
    {
        [Parameter(Position = 0, Mandatory = true)]
        public string DefaultConfig { get; set; }
        [Parameter(Mandatory = true)]
        public string OverrideConfig { get; set; }
        [Parameter(Mandatory = true)]
        public string PackagePath { get; set; }
        [Parameter(Mandatory = true)]
        public string DropFolder { get; set; }
        [Parameter(Mandatory = true)]
        public string TargetFile { get; set; }
        [Parameter(Mandatory = true)]
        public string TargetPath { get; set; }

        [Parameter(Mandatory = false)]
        public string Environment { get; set; }

        [Parameter(Mandatory = false)]
        public string RigName { get; set; }
        [Parameter]
        public string RigConfigFile { get; set; }

        protected override void ProcessRecord()
        {
            try
            {
                //So start by getting Deployment Parameters
                var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);
                var parameterService = new ParameterService(logger);
                var configurationService = new ConfigurationTransformationService(parameterService, logger);

                WriteHost($"Initialising PackagePathBuilder with build location of '{DropFolder}'");
                var builder = new PackagePathBuilder(DropFolder, logger);

                PlaceholderMappings mappings = null;
                RigManifest rigManifest = null;
                DeploymentParameters parameters;

                if (!string.IsNullOrWhiteSpace(RigConfigFile))
                {
                    WriteHost($"A unique rig config name has been passed through '{RigConfigFile}'");
                }

                //don't call for non-rig deployments
                if (!string.IsNullOrWhiteSpace(RigName))
                {
                    WriteHost($"Parsing PlaceholderMappings for config '{DefaultConfig}'");
                    mappings = parameterService.GetPlaceholderMappings(builder, DefaultConfig);

                    var rigManifestService = new RigManifestService(logger);

                    WriteHost($"Parsing RigManifest for Rig '{RigName}'");
                    rigManifest = rigManifestService.GetRigManifest(builder);

                    WriteHost($"Parsing DeploymentParameters with default config '{DefaultConfig}', OverrideConfig '{OverrideConfig}' and Rig Specific Config '{RigName}'");
                    parameters = parameterService.ParseDeploymentParameters(builder, DefaultConfig, OverrideConfig, RigConfigFile, mappings, rigManifest);
                }
                else
                {
                    WriteHost($"Parsing DeploymentParameters with default config '{DefaultConfig}', OverrideConfig '{OverrideConfig}'");
                    parameters = parameterService.ParseDeploymentParameters(builder, DefaultConfig, OverrideConfig, RigConfigFile);
                }

                WriteVerbose(parameters.ToString());

                WriteHost("Transforming Application config file: " + TargetFile);

                //Note that this can throw FileNotFoundExceptions
                configurationService.TransformApplicationConfiguration(OverrideConfig, TargetPath, PackagePath, TargetFile, parameters.Dictionary,
                        mappings, rigManifest);

                var originalFile = Path.Combine(TargetPath, TargetFile + ".original");

                if (File.Exists(originalFile))
                {
                    WriteHost("Deleting .original config file.");
                    File.Delete(originalFile);
                }

                WriteHost("Successfully transformed Application config file.");

                WriteObject(true);
            }
            catch (Exception ex)
            {
                WriteError(ex, this);
                WriteObject(false);
            }
        }
    }
}
