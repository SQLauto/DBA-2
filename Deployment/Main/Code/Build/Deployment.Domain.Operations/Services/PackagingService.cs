using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using Deployment.Common;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Domain.Operations.DeploymentOperator;
using Deployment.Domain.Operations.Packaging;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.Services
{
    public class PackagingService : IPackagingService
    {
        private readonly IDeploymentLogger _logger;
        private readonly IParameterService _parameterService;
        private readonly IDeploymentManifestService _deploymentManifestService;
        private readonly IRootPathBuilder _rootPathBuilder;
        private readonly Tuple<IDeploymentPathBuilder, IList<ICIBasePathBuilder>> _pathBuilders;

        public PackagingService(IRootPathBuilder pathBuilder, Tuple<IDeploymentPathBuilder, IList<ICIBasePathBuilder>> pathBuilders, IDeploymentManifestService deploymentManifestService, IParameterService parameterService, IDeploymentLogger logger)
        {
            _rootPathBuilder = pathBuilder;
            _pathBuilders = pathBuilders;
            _deploymentManifestService = deploymentManifestService;
            _parameterService = parameterService;
            _logger = logger;
        }

        public PackageRoleInfo CreatePackageRoleInfo(Deployment deployment)
        {
            var parametersFiles = GetDeploymentParametersFiles(deployment).Distinct(new ArchiveEntryComparer()).ToList();

            var dto = CreatePackageRoleInfo(deployment, parametersFiles);

            return dto;
        }

        private PackageRoleInfo CreatePackageRoleInfo(Deployment deployment, IList<ArchiveEntry> parametersFiles)
        {
            var parameters = GetAllParameters(parametersFiles);

            var packageRoleInfo = new PackageRoleInfo
            {
                Builder = _rootPathBuilder,
                PathBuilders = _pathBuilders,
                //PackageBuilder = new PackagePathBuilder(JumpDirectory),
                Parameters = parameters,
                RolesBeingDeployed = deployment.Machines.SelectMany(m => m.AllRoles())
                    .Select(r => r.Description)
                    .ToList()
            };

            return packageRoleInfo;
        }

        // Create the deployment archive for the given config

        public bool CreateDeploymentPackage(IDomainOperatorFactory operatorFactory, DeploymentOperationParameters parameters)
        {
            var isValid = true;

            try
            {
                var deploymentInfo = GetDeploymentObject(parameters.Groups, parameters.Servers);
                var deployment = deploymentInfo.Item1;

                if (deployment == null)
                    return false;

                var decryptionPassword = parameters.DecryptionPassword;

                _logger?.WriteLine($"Getting Deployment role files");
                var deploymentFiles = GetDeploymentFiles(operatorFactory, deployment, decryptionPassword);

                if (deploymentFiles == null)
                    return false;

                _logger?.WriteLine($"Getting Configuration Parameter files");
                var parametersFiles = GetDeploymentParametersFiles(deployment).Distinct(new ArchiveEntryComparer()).ToList();
                CentraliseParameterFilesForDeployment(parametersFiles);
                deploymentFiles.AddRange(parametersFiles);

                var dynamicConfigFiles = GetDynamicConfigFiles().Distinct(new ArchiveEntryComparer()).ToList();
                deploymentFiles.AddRange(dynamicConfigFiles);

                //Get any Files to include in build
                var packageRoleInfo = CreatePackageRoleInfo(deployment, parametersFiles);
                var packageCommand = new PackageRoleCommand(packageRoleInfo);
                var packageDeploymentFiles = packageCommand.GetDeploymentFiles();
                deploymentFiles.AddRange(packageDeploymentFiles);

                deploymentFiles.AddRange(GetDeploymentSupportFiles());
                //Stop processing Symbol files as this adds size and time to packaging etc.
                //When new work comes in, stop all together
                //deploymentFiles.AddRange(GetSymbolFiles());

                var deploymentToolFiles = GetDeploymentToolFiles().ToList();
                deploymentFiles.AddRange(deploymentToolFiles);

                // Add the config file and common roles file, not the one in dropFolder but the one we passed into this method
                string rootDirectory = _pathBuilders.Item1.BuildDirectory;
                var fileToArchive = _pathBuilders.Item1.DeploymentConfigFilePath;
                _logger?.WriteLine($"Getting Deployment Configuration file from path {fileToArchive}");
                deploymentFiles.Add(new ArchiveEntry
                {
                    FileLocation = fileToArchive,
                    FileRelativePath = FileHelper.GetFileRelativePath(fileToArchive, rootDirectory)
                });

                fileToArchive = Path.Combine(_pathBuilders.Item1.GroupsRelativeDirectory,
                        $"DeploymentGroups.{deployment.ProductGroup}.xml");
                _logger?.WriteLine($"Getting Groups file from path {fileToArchive}");
                deploymentFiles.Add(new ArchiveEntry
                {
                    FileLocation = fileToArchive,
                    FileRelativePath = FileHelper.GetFileRelativePath(fileToArchive, rootDirectory)
                });

                fileToArchive = Path.Combine(_pathBuilders.Item1.AccountsRelativeDirectory,
                        $"{deployment.Environment}.ServiceAccounts.xml");
                _logger?.WriteLine($"Getting Service Accounts file from path {fileToArchive}");
                deploymentFiles.Add(new ArchiveEntry
                {
                    FileLocation = fileToArchive,
                    FileRelativePath = FileHelper.GetFileRelativePath(fileToArchive, rootDirectory)
                });

                _logger?.WriteLine($"Getting Common Role files from path {_pathBuilders.Item1.ScriptsRelativeDirectory}");
                foreach (string commonRoleFile in deployment.CommonRoleFiles)
                {
                    fileToArchive = Path.Combine(_pathBuilders.Item1.ScriptsRelativeDirectory, commonRoleFile);
                    deploymentFiles.Add(new ArchiveEntry
                    {
                        FileLocation = fileToArchive,
                        FileRelativePath = FileHelper.GetFileRelativePath(fileToArchive, rootDirectory)
                    });
                }

                // Remove duplicates
                _logger?.WriteLine("Removing duplicate file entries");
                deploymentFiles = deploymentFiles.Distinct(new ArchiveEntryComparer()).ToList();
                _logger?.WriteLine($"Checking if Package exists and deleting from path {_rootPathBuilder.PackageDirectory}");
                if (File.Exists(Path.Combine(_rootPathBuilder.PackageDirectory, parameters.PackageFileName)))
                {

                    File.Delete(Path.Combine(_rootPathBuilder.PackageDirectory, parameters.PackageFileName));
                }

                // Verify existence of each file specified
                foreach (var file in deploymentFiles)
                {
                    if (!File.Exists(file.FileLocation))
                    {
                        throw new ApplicationException(
                            $"Error creating deployment package, cannot find file '{file.FileLocation}'");
                    }
                }

                CreateArchive(deploymentFiles, Path.Combine(_rootPathBuilder.PackageDirectory, parameters.PackageFileName));

                CopyDeploymentFilesToPackageOutput(deploymentToolFiles);

                isValid &= GenerateDeploymentManifest(deploymentInfo, parameters, _pathBuilders.Item1.AccountsRelativeDirectory);
            }
            catch (Exception ex)
            {
                isValid = false;
                _logger?.WriteError(ex);
            }

            return isValid;
        }

        private bool CreateArchive(IList<ArchiveEntry> files, string outputLocation)
        {
            _logger.WriteLine("Creating package zip file.");
            var directory = Path.GetDirectoryName(outputLocation);

            var tempFolderName = ShortGuid.NewGuid().Value;
            var combinedPath = Path.Combine(directory, tempFolderName);

            if (Directory.Exists(combinedPath))
                Directory.Delete(combinedPath, true);

            Directory.CreateDirectory(combinedPath);

            char[] delimeters = { Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar };

            using (var perfLogger = new PerformanceLogger(_logger))
            {
                _logger?.WriteLine($"Copying files to temp archive folder {combinedPath}");

                foreach (var file in files)
                {
                    var fileName = Path.GetFileName(file.FileLocation);

                    if (string.IsNullOrWhiteSpace(file.FileName) && string.IsNullOrWhiteSpace(file.FileRelativePath))
                    {
                        var targetFile = Path.Combine(combinedPath, fileName);
                        File.Copy(file.FileLocation, targetFile, true);
                        File.SetAttributes(targetFile, FileAttributes.Normal);
                        continue;
                    }

                    if (!string.IsNullOrEmpty(file.FileRelativePath) && !string.IsNullOrEmpty(file.FileName))
                    {
                        var targetDirectory = Path.Combine(combinedPath, file.FileRelativePath.TrimStart(delimeters));

                        if (!Directory.Exists(targetDirectory))
                            Directory.CreateDirectory(targetDirectory);

                        var targetFile = Path.Combine(targetDirectory, file.FileName);
                        File.Copy(file.FileLocation, targetFile, true);
                        File.SetAttributes(targetFile, FileAttributes.Normal);
                    }

                    if (!string.IsNullOrEmpty(file.FileRelativePath))
                    {
                        var pathBuilder = new StringBuilder();

                        var pathParts = file.FileRelativePath.Split(delimeters, StringSplitOptions.RemoveEmptyEntries);

                        if (pathParts.Any())
                        {
                            pathBuilder.Append(combinedPath);
                            foreach (var pathPart in pathParts)
                            {
                                pathBuilder.Append(Path.DirectorySeparatorChar).Append(pathPart);
                            }
                        }

                        var targetDirectory = pathBuilder.ToString();

                        if (!string.IsNullOrEmpty(targetDirectory) && !Directory.Exists(targetDirectory))
                            Directory.CreateDirectory(targetDirectory);

                        //what if targetDirectory is empty (as per above)?
                        var targetFile = Path.Combine(targetDirectory, fileName);

                        File.Copy(file.FileLocation, targetFile, true);
                        File.SetAttributes(targetFile, FileAttributes.Normal);
                    }
                    else //file.fileName is not empty, fileRelateivePath is
                    {
                        var copiedFileToRoot = Path.Combine(combinedPath, file.FileName);

                        File.Copy(file.FileLocation, copiedFileToRoot);
                        File.SetAttributes(copiedFileToRoot, FileAttributes.Normal);
                    }
                }

                ZipFile.CreateFromDirectory(combinedPath, outputLocation);

                _logger?.WriteLine("Removing temporary archive folder.");
                Directory.Delete(combinedPath, true);

                perfLogger.WriteLine("Finished creating zip archive.");
            }

            return true;
        }

        private Tuple<Deployment, DeploymentServer> GetDeploymentObject(IList<string> groups, IList<string> servers)
        {
            DeploymentServer deploymentMachine;

            //TODO: Some really horrible stuff here.  When building domain object, we parse all the parameters
            //However, we also do exactly the same again in below method via the configuration parameter service.
            //And even the parsing above is inefficient due to doing it multiple times.  Must find better way of handling this.
            //Probably need a single Parse set before all this that has a dictionary of parameterss etc. that then gets passed into these methods.
            var deploymentService = new DeploymentService(_logger, _parameterService);

            var validator = new DomainModelValidator(_logger);

            _logger?.WriteLine("Building Deployment model.");

            var deployment = deploymentService.GetDeployment(validator, new DomainModelFactoryBuilder(), _pathBuilders.Item1, _pathBuilders.Item2);

            deploymentMachine = new DeploymentServer(deployment.Machines.FirstOrDefault(m => m.DeploymentMachine));

            var deploymentGroupsFile = Path.Combine(_pathBuilders.Item1.GroupsRelativeDirectory,
                $"DeploymentGroups.{deployment.ProductGroup}.xml");

            var groupFilters = deploymentService.ValidateGroups(groups, deploymentGroupsFile);
            deployment = deploymentService.FilterDeployment(deployment, servers, groupFilters);

            _logger?.WriteLine($"Completed creation of Deployment model '{deployment.Name}'");

            return Tuple.Create(deployment, deploymentMachine);
        }

        private IList<ArchiveEntry> GetDeploymentFiles(IDomainOperatorFactory operatorFactory, Deployment deployment, string decryptionPassword)
        {
            var files = new List<ArchiveEntry>();
            var packageOperator = new UniversalPackageOperator(operatorFactory);

            var serviceAccountsFile = Path.Combine(_pathBuilders.Item1.AccountsRelativeDirectory,
                $"{deployment.Environment}.ServiceAccounts.xml");

            var serviceAccountsManager = new ServiceAccountsManager(decryptionPassword, _logger);
            var accounts = serviceAccountsManager.ParseFile(serviceAccountsFile);

            var configParamService = new ConfigurationParameterService(_parameterService, _pathBuilders.Item1, _pathBuilders.Item2);

            var buildDirectories = _pathBuilders.Item2.Select(ciPaths => ciPaths.BuildDirectory).ToList();

            buildDirectories.Add(_pathBuilders.Item1.BuildDirectory);

            foreach (var machine in deployment.Machines)
            {
                _logger?.WriteLine($"Getting deployment files for machine {machine.Name}");
                foreach (dynamic role in machine.AllRoles())
                {

                    var parameters = configParamService.BuildConfigurationParameters(deployment, role, accounts);

                    try
                    {
                        var deploymentFiles = packageOperator.GetDeploymentFiles(role, buildDirectories, parameters);

                        if (deploymentFiles != null)
                            files.AddRange(deploymentFiles);
                    }
                    catch (Exception ex)
                    {
                        _logger?.WriteSummary($"Error occurred getting deployment files for role '{role?.Include}'", LogResult.Error);
                        _logger?.WriteError(ex);
                        return null;
                    }
                }
            }
            return files;
        }

        private bool GenerateDeploymentManifest(Tuple<Deployment, DeploymentServer> deploymentInfo, DeploymentOperationParameters parameters, string accountsDirectory)
        {
            _logger?.WriteLine("Starting generation of Deployment Manifest file.");
            try
            {
                return _deploymentManifestService.GenerateDeploymentManifest(deploymentInfo.Item1, deploymentInfo.Item2, parameters, accountsDirectory);
            }
            catch (Exception ex)
            {
                _logger?.WriteError("There was an exception attempting to create the deployment manifest");
                _logger?.WriteError(ex);
                return false;
            }
        }

        private void CopyDeploymentFilesToPackageOutput(IList<ArchiveEntry> deploymentToolFiles = null)
        {
            var outputFolder = _pathBuilders.Item1.ToolsRelativeDirectory;

            if (!Directory.Exists(outputFolder))
            {
                Directory.CreateDirectory(outputFolder);
            }

            deploymentToolFiles = deploymentToolFiles ?? GetDeploymentToolFiles().ToList();
            foreach (var file in deploymentToolFiles)
            {
                var copyPath = Path.Combine(outputFolder, Path.GetFileName(file.FileLocation));
                File.Copy(file.FileLocation, copyPath, true);
            }
        }

        private IDictionary<string, string> GetAllParameters(IList<ArchiveEntry> parametersFiles)
        {
            var allParameters = new Dictionary<string, string>();

            foreach (var parametersFile in parametersFiles)
            {
                var parameters = _parameterService.ReadDeploymentParameters(parametersFile.FileLocation);
                foreach (var parameter in parameters.Dictionary)
                {
                    if (!allParameters.ContainsKey(parameter.Key))
                    {
                        allParameters.Add(parameter.Key, parameter.Value.Text);
                    }
                }
            }

            return allParameters;
        }

        private IEnumerable<ArchiveEntry> GetDeploymentSupportFiles()
        {
            // All the powershell scripts (excluding Uninstall scripts)
            var psScripts = Directory.GetFiles(_pathBuilders.Item1.ScriptsRelativeDirectory, "*.ps1", SearchOption.AllDirectories).ToList();
            var supportfiles = new List<string>(psScripts);

            // Dll files
            supportfiles.AddRange(Directory.GetFiles(_pathBuilders.Item1.ScriptsRelativeDirectory, "*.dll", SearchOption.AllDirectories));
            // XSL files
            supportfiles.AddRange(Directory.GetFiles(_pathBuilders.Item1.ScriptsRelativeDirectory, "*.xsl", SearchOption.AllDirectories));
            // Tools (psexec)
            supportfiles.AddRange(Directory.GetFiles(_pathBuilders.Item1.ToolsRelativeDirectory, "*.*", SearchOption.AllDirectories));
            // Software (web deploy msi)
            supportfiles.AddRange(Directory.GetFiles(_pathBuilders.Item1.SoftwareRelativeDirectory, "*.*", SearchOption.AllDirectories));
            //Powershell Modules
            supportfiles.AddRange(Directory.GetFiles(_pathBuilders.Item1.ScriptsRelativeDirectory, "*.psd1", SearchOption.AllDirectories));
            supportfiles.AddRange(Directory.GetFiles(_pathBuilders.Item1.ScriptsRelativeDirectory, "*.psm1", SearchOption.AllDirectories));

            // Helper Scripts
            if (Directory.Exists(_pathBuilders.Item1.HelperScriptsRelativeDirectory))
            {
                supportfiles.AddRange(Directory.GetFiles(_pathBuilders.Item1.HelperScriptsRelativeDirectory, "*.*", SearchOption.AllDirectories));
            }

            if (Directory.Exists(_pathBuilders.Item1.ResourceRelativeDirectory))
            {
                supportfiles.AddRange(Directory.GetFiles(_pathBuilders.Item1.ResourceRelativeDirectory, "*.*", SearchOption.AllDirectories));
            }

            return supportfiles.Select(file => new ArchiveEntry
            {
                FileLocation = file,
                FileRelativePath = GetFileRelativePath(file, _pathBuilders.Item1.BuildDirectory),
                FileName = string.Empty,
            });
        }

        private IEnumerable<ArchiveEntry> GetDeploymentParametersFiles(Deployment deployment)
        {
            var parametersFiles = new List<ArchiveEntry>();

            // Root parameters files first
            string rootConfig = deployment.Configuration;
            string rootParameterFilesPattern = $"{rootConfig}.*.parameters.xml";

            //Deployment CI Parameter Files
            Directory.GetFiles(_pathBuilders.Item1.ParametersRelativeDirectory, rootParameterFilesPattern, SearchOption.AllDirectories).ToList().ForEach(file =>
                    {
                        parametersFiles.Add(
                            new ArchiveEntry
                            {
                                FileLocation = file,
                                FileRelativePath = GetFileRelativePath(file, _pathBuilders.Item1.BuildDirectory),
                                FileName = string.Empty
                            });
                    });
            Directory.GetFiles(_pathBuilders.Item1.ParametersRelativeDirectory, $"{rootConfig}.parameters.xml", SearchOption.AllDirectories).ToList().ForEach(file =>
                    {
                        parametersFiles.Add(
                            new ArchiveEntry()
                            {
                                FileLocation = file,
                                FileRelativePath = GetFileRelativePath(file, _pathBuilders.Item1.BuildDirectory),
                                FileName = string.Empty
                            });
                    });

            //Other CI Parameter Files
            foreach(var ci in _pathBuilders.Item2)
            {
                if (!Directory.Exists(ci.ParametersRelativeDirectory))
                    continue;

                Directory.GetFiles(ci.ParametersRelativeDirectory, rootParameterFilesPattern, SearchOption.AllDirectories).ToList().ForEach(file =>
                    {
                        parametersFiles.Add(
                            new ArchiveEntry
                            {
                                FileLocation = file,
                                FileRelativePath = GetFileRelativePath(file, ci.BuildDirectory),
                                FileName = string.Empty
                            });
                    });
                Directory.GetFiles(ci.ParametersRelativeDirectory, $"{rootConfig}.parameters.xml", SearchOption.AllDirectories).ToList().ForEach(file =>
                    {
                        parametersFiles.Add(
                            new ArchiveEntry
                            {
                                FileLocation = file,
                                FileRelativePath = GetFileRelativePath(file, ci.BuildDirectory),
                                FileName = string.Empty
                            });
                    }
                    );
            }

            // Any overridden parameters files
            var roles = deployment.Machines.SelectMany(m => m.AllRoles()).ToList();
            //Deployment CI Files
            GetParameterFilesForPackaging(roles, _pathBuilders.Item1.ParametersRelativeDirectory, "{0}.*.Parameters.xml").ForEach(file =>
                {
                    parametersFiles.Add(
                        new ArchiveEntry
                        {
                            FileLocation = file,
                            FileRelativePath = GetFileRelativePath(file, _pathBuilders.Item1.BuildDirectory),
                            FileName = string.Empty
                        });
                });
            GetParameterFilesForPackaging(roles, _pathBuilders.Item1.ParametersRelativeDirectory, "{0}.Parameters.xml").ForEach(file =>
            {
                parametersFiles.Add(
                    new ArchiveEntry
                    {
                        FileLocation = file,
                        FileRelativePath = GetFileRelativePath(file, _pathBuilders.Item1.BuildDirectory),
                        FileName = string.Empty
                    });
            });
            //Other CI parameter Files
            foreach (var ci in _pathBuilders.Item2)
            {
                if (!Directory.Exists(ci.ParametersRelativeDirectory))
                    continue;

                GetParameterFilesForPackaging(roles, ci.ParametersRelativeDirectory, "{0}.*.Parameters.xml").ForEach(file =>
                {
                    parametersFiles.Add(
                        new ArchiveEntry
                        {
                            FileLocation = file,
                            FileRelativePath = GetFileRelativePath(file, ci.BuildDirectory),
                            FileName = string.Empty
                        });
                });
                GetParameterFilesForPackaging(roles, ci.ParametersRelativeDirectory, "{0}.Parameters.xml").ForEach(file =>
                {
                    parametersFiles.Add(
                        new ArchiveEntry
                        {
                            FileLocation = file,
                            FileRelativePath = GetFileRelativePath(file, ci.BuildDirectory),
                            FileName = string.Empty
                        });
                });
            }

            if (parametersFiles.Any())
                return parametersFiles;

            _logger?.WriteWarn("No Deployment Parameters were found for any config. Exiting.");
            throw new Exception("No Deployment Parameters were found for any config.");
        }

        private void CentraliseParameterFilesForDeployment(IList<ArchiveEntry> parameterFiles)
        {
            foreach(var parameterFile in parameterFiles)
            {
                var sourceLocation = parameterFile.FileLocation;
                var targetLocation = Path.Combine(_pathBuilders.Item1.ParametersRelativeDirectory, Path.GetFileName(parameterFile.FileLocation));
                if(!File.Exists(targetLocation))
                    File.Copy(sourceLocation, targetLocation);
            }
        }

        private IEnumerable<ArchiveEntry> GetDynamicConfigFiles()
        {
            var parametersFiles = new List<ArchiveEntry>();

            // Root (Deployment CI) files first
            Directory.GetFiles(_pathBuilders.Item1.PlaceholderMappingsDirectory, "*", SearchOption.AllDirectories).ToList().ForEach(file =>
            {
                parametersFiles.Add(
                    new ArchiveEntry
                    {
                        FileLocation = file,
                        FileRelativePath = GetFileRelativePath(file, _pathBuilders.Item1.BuildDirectory),
                        FileName = string.Empty
                    });
            });
            Directory.GetFiles(_pathBuilders.Item1.UniqueEnvironmentParametersDirectory, "*", SearchOption.AllDirectories).ToList().ForEach(file =>
            {
                parametersFiles.Add(
                    new ArchiveEntry
                    {
                        FileLocation = file,
                        FileRelativePath = GetFileRelativePath(file, _pathBuilders.Item1.BuildDirectory),
                        FileName = string.Empty
                    });
            });

            // Individual CI Config Files
            foreach (var ci in _pathBuilders.Item2)
            {
                if (!Directory.Exists(ci.PlaceholderMappingsDirectory))
                    continue;

                Directory.GetFiles(ci.PlaceholderMappingsDirectory, "*", SearchOption.AllDirectories).ToList().ForEach(file =>
                {
                    parametersFiles.Add(
                        new ArchiveEntry
                        {
                            FileLocation = file,
                            FileRelativePath = GetFileRelativePath(file, ci.BuildDirectory),
                            FileName = string.Empty
                        });
                });
                if (!Directory.Exists(ci.UniqueEnvironmentParametersDirectory))
                    continue;

                Directory.GetFiles(ci.UniqueEnvironmentParametersDirectory, "*", SearchOption.AllDirectories).ToList().ForEach(file =>
                {
                    parametersFiles.Add(
                        new ArchiveEntry
                        {
                            FileLocation = file,
                            FileRelativePath = GetFileRelativePath(file, ci.BuildDirectory),
                            FileName = string.Empty
                        });
                });
            }

            return parametersFiles;
        }

        private IList<string> GetParameterFilesForPackaging(IList<IBaseRole> roles, string parametersDirectory, string filterPattern)
        {
            var paramFiles = new List<string>();
            roles.ForEach(r =>
                paramFiles.AddRange(
                    Directory.GetFiles(parametersDirectory, string.Format(filterPattern, r.Configuration),
                        SearchOption.AllDirectories).ToList()));

            return paramFiles;
        }

        private IEnumerable<ArchiveEntry> GetDeploymentToolFiles()
        {
            // The deployment tool will live in the roof of the drop folder, we just need to work out all its dependancies
            const string toolExe = "DeploymentTool.exe";
            var toolFullPath = Path.Combine(_pathBuilders.Item1.BuildDirectory, toolExe);

            _logger?.WriteLine($"Getting Deployment tool dependencies from path {toolFullPath}");

            var files = DependencyHelper.GetDependencies(toolFullPath);

            return files.Select(file => new ArchiveEntry
            {
                FileLocation = file,
                FileRelativePath = @"Deployment\Tools\Deployment Tool"
            });
        }

        // Get the relative path of file in the drop folder
        private string GetFileRelativePath(string file, string dropFolder)
        {
            return FileHelper.GetFileRelativePath(file, dropFolder);
        }
    }
}
