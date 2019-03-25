using System;
using System.Collections.Generic;
using System.Linq;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class FileSystemDeploy : BaseRole,  IDeploymentRole, IPostDeploymentRole
    {
        public FileSystemDeploy(string configuration)
        {
            FileSystemRoles = new List<IFileSystemRole>();
            Configuration = configuration;
            RoleType = "File System Setup";
        }
        public IList<IFileSystemRole> FileSystemRoles { get; }

        public IList<CopyItem> CopyItems => FileSystemRoles.OfType<CopyItem>().ToList();

        public IList<FolderDeploy> CreateFolderDeploys =>
            FileSystemRoles.OfType<FolderDeploy>().Where(fd => fd.Action == DeploymentAction.Install).ToList();

        public IList<FolderDeploy> RemoveFolderDeploys =>
            FileSystemRoles.OfType<FolderDeploy>().Where(fd => fd.Action == DeploymentAction.Uninstall).ToList();
    }
}