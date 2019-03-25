using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Text.RegularExpressions;
using Deployment.Common.Logging;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.Services
{
    public class PreviewHelper
    {
        //private readonly StringBuilder _logBuilder;
        private readonly IDeploymentLogger _logger;

        public PreviewHelper(IDeploymentLogger logger)
        {
            _logger = logger;
        }

        public bool PreviewPackage(IRootPathBuilder pathBuilder, DeploymentOperationParameters operationParameters, string driveLetter)
        {
            string space = "  ";
            string pattern = $@"(?i){driveLetter}:\\Tfl\\";
            string appDir;
            string environmentName;
            var regex = new Regex(pattern);

            var pathBuilders = pathBuilder.CreateChildPathBuilders(operationParameters.DeploymentConfigFileName);

            var outputDir = pathBuilder.OutputDirectory;
            var packageFileName = operationParameters.PackageFileName;
            var configFile = pathBuilders.Item1.DeploymentConfigFilePath;

            if (Directory.Exists(outputDir))
            {
                _logger?.WriteLine("Output directory exists, deleting directory so process is idempotent");
                Directory.Delete(outputDir, true);
            }

            _logger?.WriteLine("Creating Output Directories...");
            var packageFolderPath = pathBuilder.PackageDirectory;
            var previewRootfolderPath = pathBuilder.RootDirectory;
            CreateDirectoryWithModifyForEveryone(pathBuilder.OutputDirectory);
            CreateDirectoryWithModifyForEveryone(packageFolderPath);
            CreateDirectoryWithModifyForEveryone(previewRootfolderPath);
            _logger?.WriteLine("Done");

            _logger?.WriteLine(
                $"Unzipping package file {Path.GetFileName(packageFileName)} to {pathBuilder.PackageDirectory}...");
            ZipFile.ExtractToDirectory(packageFileName, packageFolderPath);
            SetModifyForEveryoneOnDirectory(packageFolderPath);
            _logger?.WriteLine("Done");

            _logger?.WriteLine($"Searching package for Deployment Config file {configFile}...");

            ICollection<ZipArchiveEntry> configFileEntries = new Collection<ZipArchiveEntry>();

            using (var archive = ZipFile.OpenRead(packageFileName))
            {
                foreach (var entry in archive.Entries)
                {
                    if (entry.Name == Path.GetFileName(configFile))
                    {
                        configFileEntries.Add(entry);
                    }
                }
            }
            if(configFileEntries.Count > 0)
            {
                _logger?.WriteLine("Done");
            }
            else
            {
                _logger?.WriteWarn("Failed");
                throw new FileNotFoundException(
                    $"Unable to find Deployment Config {configFile} in package {Path.GetFileName(packageFileName)}");
            }

            _logger?.WriteLine("Reading Deployment Config File...");

            var parameterService = new ParameterService(_logger);
            var validator = new DomainModelValidator();

            var deploymentService = new DeploymentService(_logger, parameterService);

            var deployment = deploymentService.GetDeployment(validator, new DomainModelFactoryBuilder(), pathBuilders.Item1, pathBuilders.Item2);

            var rootEnvironmentName = deployment.Configuration;
            _logger?.WriteLine("Done");

            _logger?.WriteLine("Starting search for Roles");

            var transformationService = new ConfigurationTransformationService(parameterService, _logger);

            var webDeploys = deploymentService.GetWebDeployments(deployment);

            foreach (var machine in webDeploys.Machines)
            {
                _logger?.WriteLine($"{space}Checking Web Roles for {machine.Name}");
                string previewfolderPath = Path.Combine(previewRootfolderPath, machine.Name);

                foreach (var role in machine.DeploymentRoles)
                {
                    environmentName = role.Configuration != rootEnvironmentName ? role.Configuration : rootEnvironmentName;

                    var webRole = (WebDeploy)role;

                    _logger?.WriteLine($"{space + space}Found Web Role {webRole.Description}, Getting Configs...");
                    if (webRole.Package != null)
                    {
                        appDir = Path.Combine(previewfolderPath, regex.Replace(webRole.Site.PhysicalPath, string.Empty));
                        Directory.CreateDirectory(appDir);

                        var packageRootPath = Path.Combine(packageFolderPath, "_PublishedWebsites", webRole.Package.Name + "_Package");

                        string setParametersFile = Path.Combine(packageRootPath, webRole.Package.Name + ".SetParameters.xml");

                        var parameters = parameterService.ParseDeploymentParameters(pathBuilders.Item1, deployment.Configuration, webRole.Configuration, pathBuilders.Item2);
                        var corrections = new Dictionary<string, string> { { "IIS Web Application Name", webRole.Site.Name } };
                        transformationService.TransformWebParametersFile(setParametersFile, environmentName, parameters.Dictionary, corrections);

                        transformationService.UpdateWebConfigurationFiles(packageFolderPath, setParametersFile, webRole.Package.Name);

                        if (!(string.IsNullOrEmpty(webRole.AssemblyToVersionFrom)))
                        {
                            UpdateWebAssemblyVersion(packageFolderPath, webRole.Package.Name, webRole.AssemblyToVersionFrom);
                        }

                        CopyWebConfigFiles(Path.Combine(packageRootPath, webRole.Package.Name, "Content"), appDir, false);
                    }

                    _logger?.WriteLine($"{space + space}Done");
                }
            }

            var serviceDeploys = deploymentService.GetServiceDeployments(deployment);

            foreach (var machine in serviceDeploys.Machines)
            {
                _logger?.WriteLine($"{space}Checking Service Deploy Roles for {machine.Name}");
                string previewfolderPath = Path.Combine(previewRootfolderPath, machine.Name);

                foreach (var role in machine.DeploymentRoles)
                {
                   var serviceRole = (ServiceDeploy) role;
                    environmentName = role.Configuration != rootEnvironmentName ? role.Configuration : rootEnvironmentName;

                    CreateMachineFolder(previewfolderPath);

                    _logger?.WriteLine($"{space + space}Found Service Role {serviceRole.Description}, Getting Configs...");
                    if (serviceRole.Action == MsiAction.Install)
                    {
                        appDir = Path.Combine(previewfolderPath,
                            regex.Replace(serviceRole.MsiDeploy.InstallationLocation, string.Empty));
                        Directory.CreateDirectory(appDir);
                        foreach (var config in serviceRole.MsiDeploy.Configs)
                        {
                            var parameters = parameterService.ParseDeploymentParameters(pathBuilders.Item1, deployment.Configuration, role.Configuration, pathBuilders.Item2);
                            transformationService.TransformApplicationConfiguration(environmentName, appDir,
                                packageFolderPath, config.Name, parameters.Dictionary);
                        }
                    }
                    _logger?.WriteLine(space + space + "Done");
                }
            }

            var msiDeploys = deploymentService.GetMsiDeployments(deployment);

            foreach (var machine in msiDeploys.Machines)
            {
                _logger?.WriteLine($"{space}Checking MSI Deploy Roles for {machine.Name}");
                string previewfolderPath = Path.Combine(previewRootfolderPath, machine.Name);

                foreach (var role in machine.DeploymentRoles)
                {
                    environmentName = role.Configuration != rootEnvironmentName
                        ? role.Configuration
                        : rootEnvironmentName;

                    var msiRole = (MsiDeploy)role;

                    CreateMachineFolder(previewfolderPath);

                    _logger?.WriteLine($"{space + space}Found MSI Role {msiRole.Description}, Getting Configs...");
                    if (msiRole.Action == MsiAction.Install)
                    {
                        appDir = Path.Combine(previewfolderPath,
                            regex.Replace(msiRole.InstallationLocation, string.Empty));
                        Directory.CreateDirectory(appDir);

                        foreach (var config in msiRole.Configs)
                        {
                            var parameters = parameterService.ParseDeploymentParameters(pathBuilders.Item1, deployment.Configuration, role.Configuration, pathBuilders.Item2);

                            transformationService.TransformApplicationConfiguration(environmentName, appDir,
                                packageFolderPath, config.Name, parameters.Dictionary);
                        }
                    }
                    _logger?.WriteLine(space + space + "Done");
                }
            }

            _logger?.WriteLine("Finished searching for roles");

            return true;
        }

        private void CreateDirectoryWithModifyForEveryone(string directory)
        {
            Directory.CreateDirectory(directory);
            SetModifyForEveryoneOnDirectory(directory);
        }

        private void SetModifyForEveryoneOnDirectory(string directory)
        {
            DirectorySecurity sec = Directory.GetAccessControl(directory);
            // Using this instead of the "Everyone" string means we work on non-English systems.
            SecurityIdentifier everyone = new SecurityIdentifier(WellKnownSidType.WorldSid, null);
            sec.AddAccessRule(new FileSystemAccessRule(everyone, FileSystemRights.Modify | FileSystemRights.Synchronize, InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit, PropagationFlags.None, AccessControlType.Allow));
            Directory.SetAccessControl(directory, sec);
        }

        private void UpdateWebAssemblyVersion(string packageFolderPath, string packageName, string assemblytoVersionFrom)
        {
            string version = null;
            string token = "Token_TFLAssemblyVersion";

            string webPackagePath = packageFolderPath + "\\_PublishedWebsites\\" + packageName + "_Package\\" + packageName;
            string webPackageContentPath = webPackagePath + "\\Content";
            string webPackageBinPath = webPackageContentPath + "\\bin";

            string DLLtoVersion = webPackageBinPath + "\\" + assemblytoVersionFrom;

            //Version versionInfo = Assembly.ReflectionOnlyLoadFrom(DLLtoVersion).GetName().Version;
            Version versionInfo =  AssemblyName.GetAssemblyName(DLLtoVersion).Version;
            version = versionInfo.Major + "." + versionInfo.Minor + "." + versionInfo.Build + "." + versionInfo.Revision;

            foreach(string configFile in Directory.GetFiles(webPackageContentPath, "*.config"))
            {
                string configFileContent = File.ReadAllText(configFile);
                if (configFileContent.Contains(token))
                {
                    configFileContent = configFileContent.Replace(token, version);
                    File.WriteAllText(configFile, configFileContent);
                }
            }
        }

        private void CopyWebConfigFiles(string folderPath, string destination, bool createDir)
        {
            foreach(string fileName in Directory.GetFiles(folderPath,"*.config", SearchOption.TopDirectoryOnly))
            {
                if(createDir)
                {
                    destination = destination + "\\" + new DirectoryInfo(Path.GetDirectoryName(fileName)).Name;
                    Directory.CreateDirectory(destination);
                    createDir = false;
                }
                File.Copy(fileName, destination + "\\" + Path.GetFileName(fileName), true);
            }

            foreach(string directory in Directory.GetDirectories(folderPath))
            {
                CopyWebConfigFiles(directory, destination, true);
            }
        }

        private void CreateMachineFolder(string folderPath)
        {
            if(!(Directory.Exists(folderPath)))
            {
                Directory.CreateDirectory(folderPath);
            }
        }
    }
}
