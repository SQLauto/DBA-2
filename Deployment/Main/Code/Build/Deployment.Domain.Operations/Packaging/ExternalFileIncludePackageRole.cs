using System.Collections.Generic;
using System.IO;
using System.Linq;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;

namespace Deployment.Domain.Operations.Packaging
{
    public class ExternalFileIncludePackageRole : IPackageRole
    {
        public bool HasWorkToDo()
        {
            var rolesBeingDeployed = RoleInfo.RolesBeingDeployed;
            string fileIncludeConfig = RoleInfo.PathBuilders.Item1.RoleToParameterMappingsFilePath;
            var packagingFileConfig = GetExternalPackagingConfiguration(rolesBeingDeployed, fileIncludeConfig);
            if (packagingFileConfig == null || !packagingFileConfig.Any())
            {
                return false;
            }

            return true;
        }

        public bool PreDeploymentValidate(List<string> outputLocations, IDeploymentLogger logger)
        {
            //TODO: Implement PreDeploymentValidation for ExternalFileInclude?
            return true;
        }

        public IList<ArchiveEntry> GetDeploymentFiles()
        {
            var externalFilesToInclude = GetExternalFilesToInclude();
            CreateFolderAndCopyFilesForExternalFilesToInclude(externalFilesToInclude);

            var deploymentFiles = new List<ArchiveEntry>();
            foreach (var archiveEntry in externalFilesToInclude)
            {
                var externalEntry = new ArchiveEntry
                {
                    FileName = archiveEntry.FileName,
                    FileLocation = Path.Combine(RoleInfo.PathBuilders.Item1.ExternalResourcesRelativeDirectory, archiveEntry.FileName),
                    FileRelativePath = archiveEntry.FileRelativePath
                };

                deploymentFiles.Add(externalEntry);
            }

            return deploymentFiles;
        }

        private IList<ArchiveEntry> GetExternalFilesToInclude()
        {
            var rolesBeingDeployed = RoleInfo.RolesBeingDeployed;
            var parameters = RoleInfo.Parameters;
            string fileIncludeConfig = RoleInfo.PathBuilders.Item1.RoleToParameterMappingsFilePath;
            var packagingFileConfig = GetExternalPackagingConfiguration(rolesBeingDeployed, fileIncludeConfig);
            if (packagingFileConfig == null || !packagingFileConfig.Any())
            {
                return new List<ArchiveEntry>();
            }

            var filesToInclude = GetArchiveEntriesForExternalFilesToPackage(packagingFileConfig, parameters);
            return filesToInclude;
        }

        private IList<PackagingFileConfig> GetExternalPackagingConfiguration(IList<string> rolesBeingDeployed, string fileIncludeConfig)
        {
            var packagingFileConfig = FileIncludeInPackagingXmlReader.Read(fileIncludeConfig);

            if (!packagingFileConfig.Any())
            {
                return packagingFileConfig;
            }

            var configsOfInterest = packagingFileConfig.Join(rolesBeingDeployed,
                                                            pfConfig => pfConfig.DeploymentRoleName,
                                                            role => role, (pfConfig, role) => pfConfig
                                                            ).ToList();

            return configsOfInterest;
        }

        private List<ArchiveEntry> GetArchiveEntriesForExternalFilesToPackage(IList<PackagingFileConfig> packagingFileConfig, IDictionary<string, string> parameters)
        {
            var entries = new List<ArchiveEntry>();
            foreach (var config in packagingFileConfig)
            {
                var fileName = parameters[config.ParameterFileName];
                var path = parameters[config.ParameterDirectoryPath];
                var fullpath = Path.Combine(path, fileName);
                var relativeFilePath = string.Empty;
                ArchiveEntry entry;
                relativeFilePath = FileHelper.GetFileRelativePath(                    
                    Path.Combine(RoleInfo.PathBuilders.Item1.BuildDirectory, RoleInfo.PathBuilders.Item1.ExternalResourcesFolder, fileName),
                    RoleInfo.PathBuilders.Item1.BuildDirectory);
                entry = new ArchiveEntry { FileLocation = fullpath, FileRelativePath = relativeFilePath, FileName = fileName };  
                entries.Add(entry);
            }

            return entries;
        }

        private void CreateFolderAndCopyFilesForExternalFilesToInclude(IList<ArchiveEntry> externalFilesToInclude)
        {
            string externalResourcesAbsolutePath = RoleInfo.PathBuilders.Item1.ExternalResourcesRelativeDirectory;
            if (Directory.Exists(externalResourcesAbsolutePath))
            {
                Directory.Delete(externalResourcesAbsolutePath, true);
            }

            Directory.CreateDirectory(externalResourcesAbsolutePath);

            foreach (var archiveEntry in externalFilesToInclude)
            {
                var fullFilePath = archiveEntry.FileLocation;
                var relativeFilePathForPackaging = archiveEntry.FileRelativePath;
                File.Copy(fullFilePath, Path.Combine(RoleInfo.PathBuilders.Item1.ExternalResourcesRelativeDirectory, archiveEntry.FileName));
            }
        }

        public IPackageRoleInfo RoleInfo { get; set; }
    }
}