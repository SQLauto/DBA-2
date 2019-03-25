using System.Collections.Generic;
using System.IO;
using System.Management.Automation;
using Deployment.Domain.Operations.Services;
using Tfl.PowerShell.Common;
using System;
using Deployment.Domain.Parameters;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsData.Update, "WebParametersFile")]
    [OutputType(typeof(bool))]
    public class UpdateWebParametersFileCommand : PSCmdletBase
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
        public string PackageName { get; set; }

        [Parameter(Mandatory = true)]
        public string SiteName { get; set; }

        [Parameter(Mandatory = true)]
        public string Environment { get; set; }

        [Parameter(Mandatory = false)]
        public string RigName { get; set; }
        [Parameter]
        public string RigConfigFile { get; set; }

        protected override void ProcessRecord()
        {
            try
            {
                var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);

                //So start by getting Deployment Paramers
                var parameterService = new ParameterService(logger);
                var configurationService = new ConfigurationTransformationService(parameterService,logger);
                var rigManifestService = new RigManifestService(logger);

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

                var setParametersFile = Path.Combine(PackagePath, PackageName + ".SetParameters.xml");
                WriteHost($"Transforming SetParameters file {setParametersFile}");

                var corrections = new Dictionary<string, string> {{"IIS Web Application Name", SiteName}};
                configurationService.TransformWebParametersFile(setParametersFile, OverrideConfig, parameters.Dictionary, corrections, mappings, rigManifest);

                WriteHost("Successfully transformed web SetParameters file.");

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
