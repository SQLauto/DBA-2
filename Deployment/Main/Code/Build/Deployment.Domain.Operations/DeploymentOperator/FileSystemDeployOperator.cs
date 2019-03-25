using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Deployment.Common;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class FileSystemDeployOperator : IDeploymentOperator<FileSystemDeploy>
    {
        private readonly IDeploymentLogger _logger;

        public FileSystemDeployOperator(IParameterService parameterService = null, IDeploymentLogger logger = null)
        {
            _logger = logger;
        }

        public bool PreDeploymentValidate(FileSystemDeploy role, ConfigurationParameters parameters, List<string> outputLocations)
        {
            bool isValid = true;

            foreach (var copyItem in role.CopyItems)
            {
               if (!PreDeploymentValidate(copyItem, outputLocations))
               {
                isValid = false;
               }
            }

            return isValid;
        }

        private bool PreDeploymentValidate(CopyItem copyItem, List<string> outputLocations)
        {
            var foundFile = false;
            if (copyItem.Source.Contains("ExternalResources"))
                return true;

            foreach (string location in outputLocations)
            {
                string sourceFileorPath = Path.Combine(location, copyItem.Source);
                if (!Directory.Exists(sourceFileorPath) && !File.Exists(sourceFileorPath))
                {
                    foundFile = false;
                }
                else
                {
                    foundFile = true;
                    break;
                }
            }

            if(!foundFile)
                _logger?.WriteLine($"Source '{copyItem.Source}' not found for CopyItem");

            return foundFile;
        }

        public IList<ArchiveEntry> GetDeploymentFiles(FileSystemDeploy role, List<string> dropFolders, ConfigurationParameters parameters)
        {
            // Nothing needed for create folders
            // Copy items
            var archiveEntries = new List<ArchiveEntry>();

            role.CopyItems.ForEach(ci => archiveEntries.AddRange(GetDeploymentFiles(ci, dropFolders)));

            return archiveEntries;
        }

        public IList<ArchiveEntry> GetDeploymentFiles(CopyItem copyItem, List<string> dropFolders)
        {
            bool pathIsAnExternalIncludeFile = copyItem.Source.Contains("ExternalResources");
            if (pathIsAnExternalIncludeFile)
            {
                return new List<ArchiveEntry>();
            }

            var dropFolder = string.Empty;

            foreach (string location in dropFolders)
            {
                string sourceFileorPath = Path.Combine(location, copyItem.Source);
                if (!Directory.Exists(sourceFileorPath) && !File.Exists(sourceFileorPath))
                {
                    continue;
                }                

                dropFolder = location;
                break;
            }

            var searchOption = copyItem.Recurse ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;

            List<string> fileToCopy;
            if (copyItem.IsAbsolutePath == false)
            {
                fileToCopy = Directory.GetFiles(Path.Combine(dropFolder, copyItem.Source), copyItem.Filter,
                    searchOption).ToList();
            }
            else
            {
                var absolutePath = new List<string>() { Path.Combine(dropFolder, copyItem.Source) };
                fileToCopy = absolutePath;
            }


            return fileToCopy.Select(file => new ArchiveEntry
            {
                FileLocation = file,
                FileRelativePath = FileHelper.GetFileRelativePath(file, dropFolder),
                FileName = string.Empty
            }).ToList();
        }

        public bool PostDeploymentValidate(PostDeployParameters postDeployParameters, FileSystemDeploy role)
        {
            bool isValid = true;

            // We could test that all files that were meant to be copied from the build location are on the target server. However, this would then
            // mean we needed access to the build 'package' when we try to validate. This may not always be the case if we try to validate an environment some time after
            // doing a deployment. So, decided not to perform the test here.

            // Create folders
            foreach (var fileSystemRole in role.FileSystemRoles)
            {
                var folder = fileSystemRole as FolderDeploy;
                if (folder != null)
                {
                    var folderActionIsValid = folder.Action == DeploymentAction.Install
                        ? PostDeploymentValidateCreateFolder(postDeployParameters.Machine, folder, postDeployParameters.DriveLetter)
                        : PostDeploymentValidateRemoveFolder(postDeployParameters.Machine, folder, postDeployParameters.DriveLetter);

                    if (!folderActionIsValid)
                    {
                        isValid = false;
                    }
                }
            }

            return isValid;
        }

        private bool PostDeploymentValidateRemoveFolder(Machine machine, FolderDeploy folder, string driveLetter)
        {
            var machineName = machine.DeploymentAddress;

            string target = folder.TargetPath.TrimStart('\\', '/'); // very important, net use will fail if these leading \\'s are present
            target = target.Replace("{DriveLetter}", driveLetter);
            string fullPath = folder.IsAbsolutePath ? target : $"\\\\{machineName}\\{target}";

            bool result;

            using (var timer = new PerformanceLogger(_logger))
            {
                try
                {
                    result = !Directory.Exists(fullPath);

                    var message = result
                        ? $"Folder '{fullPath}' was removed from '{machineName}'."
                        : $"Folder '{fullPath}' was not removed from '{machineName}'.";

                    timer.WriteSummary(message, result ? LogResult.Success : LogResult.Fail);
                }
                catch (Exception ex)
                {
                    timer.WriteSummary($"Unable to locate '{fullPath}'on '{machineName}'.", LogResult.Error);
                    _logger?.WriteError(ex);
                    result = false;
                }
            }

            return result;
        }

        private bool PostDeploymentValidateCreateFolder(Machine machine, FolderDeploy folder, string driveLetter)
        {
            var machineName = machine.DeploymentAddress;

            string target = folder.IsAbsolutePath ? folder.TargetPath : folder.TargetPath.TrimStart('\\', '/'); // very important, net use will fail if these leading \\'s are present
            target = target.Replace("{DriveLetter}", driveLetter);
            string fullPath = folder.IsAbsolutePath ? target : $"\\\\{machineName}\\{target}";
            bool result;

            using (var timer = new PerformanceLogger(_logger))
            {
                try
                {
                    result = Directory.Exists(fullPath);

                    var message = result
                        ? $"Folder '{fullPath}' was found on '{machine.Name}'."
                        : $"Unable to locate '{fullPath}'on '{machine.Name}'.";

                    timer.WriteSummary(message, result ? LogResult.Success : LogResult.Fail);
                }
                catch (Exception ex)
                {
                    timer.WriteSummary(
                        $"Unable to locate '{fullPath}'on '{machine.Name}'.", LogResult.Error);
                    _logger?.WriteError(ex);
                    result = false;
                }
            }

            return result;
        }
    }
}