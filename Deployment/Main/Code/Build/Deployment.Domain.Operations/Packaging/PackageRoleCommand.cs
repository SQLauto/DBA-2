using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using Deployment.Common.Logging;

namespace Deployment.Domain.Operations.Packaging
{
    public class PackageRoleCommand : IPackageRole
    {
        private static Lazy<List<IPackageRole>> _packageRoles;

        public PackageRoleCommand(IPackageRoleInfo packageRoleInfo)
        {
            RoleInfo = packageRoleInfo;
            _packageRoles = new Lazy<List<IPackageRole>>(()=> new List<IPackageRole> { new ExternalFileIncludePackageRole() }, LazyThreadSafetyMode.ExecutionAndPublication);
        }

        public IPackageRoleInfo RoleInfo { get; set; }

        public bool PreDeploymentValidate(List<string> outputLocations, IDeploymentLogger logger)
        {
            var relevantRoles = GetRelevantPackageRoles();
            bool success = true;

            foreach (var role in relevantRoles)
            {
                success &= role.PreDeploymentValidate(outputLocations, logger);
            }

            return success;
        }

        public IList<ArchiveEntry> GetDeploymentFiles()
        {
            var relevantRoles = GetRelevantPackageRoles();
            var archiveEntries = new List<ArchiveEntry>();

            foreach (var role in relevantRoles)
            {
                var entries = role.GetDeploymentFiles();
                if (entries != null)
                {
                    archiveEntries.AddRange(entries);
                }
            }

            return archiveEntries;
        }

        private IList<IPackageRole> GetRelevantPackageRoles()
        {
            _packageRoles.Value.ForEach(role => { role.RoleInfo = RoleInfo; });
            var relevantRoles = _packageRoles.Value.Where(role => role.HasWorkToDo()).ToList();

            return relevantRoles;
        }

        public bool HasWorkToDo()
        {
            return true;
        }
    }
}