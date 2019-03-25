using System.Collections.Generic;
using System.IO;
using Deployment.Common.Logging;
using Deployment.Domain.Parameters;

namespace Deployment.Domain.Operations.Services
{
    public class PatchScriptParameterService : IPatchScriptParameterService
    {
        private readonly IParameterService _parameterService;
        private readonly IPackagePathBuilder _packagePathBuilder;
        private readonly IDeploymentLogger _logger;

        public PatchScriptParameterService(IDeploymentLogger logger = null)
        {
            _logger = logger;
        }

        public PatchScriptParameterService(IParameterService parameterService, IPackagePathBuilder packagePathBuilder, IDeploymentLogger logger = null) : this(logger)
        {
            _parameterService = parameterService;
            _packagePathBuilder = packagePathBuilder;
        }

        public void WritePatchScriptParameterFile(string targetFile, string defaultConfig, string overrideConfig, string rigName = null, string rigConfigFile = null)
        {
            var deploymentParameters = GetDbDeploymentParameters(defaultConfig, overrideConfig, rigName, rigConfigFile);

            using (var fileStream = new FileStream(targetFile, FileMode.Create))
            {
                using (var sw = new StreamWriter(fileStream))
                {
                    foreach (var kvp in deploymentParameters.Dictionary)
                    {
                        var line = $@":setvar {kvp.Key} ""{ConvertToSqlString(kvp.Value.Text)}""";

                        sw.WriteLine(line);
                    }
                }
            }
        }

        public void WritePatchScriptRunFile(string scriptRoot, string targetFile, string sourceFile, string dropFolder,
            string targetDatabase, string dataSource, string helperScriptsPath, string parameterFilePath, string environment, string driveLetter)
        {
            var strings = GetCommonDbVariables(scriptRoot, dropFolder, targetDatabase, dataSource, helperScriptsPath, environment, driveLetter);

            using (var fileStream = new FileStream(targetFile, FileMode.Create))
            {
                using (var sw = new StreamWriter(fileStream))
                {
                    foreach (var s in strings)
                    {
                        sw.WriteLine(s);
                    }

                    //write line to reference parameters file
                    sw.WriteLine("GO");
                    sw.WriteLine($@":r ""{parameterFilePath}""");
                    sw.WriteLine("GO");

                    using (var reader = new StreamReader(sourceFile)) // was current = base sql file to read back into ToRun file after params added.
                    {
                        while (!reader.EndOfStream)
                        {
                            sw.WriteLine(reader.ReadLine());
                        }
                    }
                }
            }
        }

        private DeploymentParameters GetDbDeploymentParameters(string defaultConfig, string overrideConfig, string rigName, string rigConfigFile)
        {
            PlaceholderMappings mappings = null;
            RigManifest rigManifest = null;

            if (!string.IsNullOrWhiteSpace(rigName))
            {
                var rigManifestService = new RigManifestService(_logger);
                rigManifest = rigManifestService.GetRigManifest(_packagePathBuilder);
                mappings = _parameterService.GetPlaceholderMappings(_packagePathBuilder, defaultConfig);
            }

            var parameters = _parameterService.ParseDeploymentParameters(_packagePathBuilder, defaultConfig, overrideConfig, rigConfigFile, mappings, rigManifest);

            return parameters;
        }

        private IList<string> GetCommonDbVariables(string scriptPath, string dropFolder, string targetDatabase, string dataSource,
                string helperScriptsPath, string environment, string driveLetter)
        {
            var temp = new DirectoryInfo(dropFolder);
            var deployFolder = temp.Parent.FullName;
            var errorLogPath = Path.Combine(deployFolder, "LogsDb", targetDatabase);

            if (!Directory.Exists(errorLogPath))
                Directory.CreateDirectory(errorLogPath);

            var variables = new List<string>
            {
                $@":setvar scriptPath ""{scriptPath}""",
                $@":setvar path ""{scriptPath}""",
                $@":setvar databasename ""{targetDatabase}""",
                $@":setvar servername ""{dataSource}""",
                $@":setvar deploymentHelpersPath ""{helperScriptsPath}""",
                $@":setvar Environment ""{environment}""",
                $@":setvar errorLogPath ""{errorLogPath}""",
                $@":setvar driveletter ""{driveLetter}"""
            };

            return variables;
        }

        private string ConvertToSqlString(string inputValue)
        {
            return inputValue.Replace("'", "''").Replace("\"", "\"\"");
        }
    }
}