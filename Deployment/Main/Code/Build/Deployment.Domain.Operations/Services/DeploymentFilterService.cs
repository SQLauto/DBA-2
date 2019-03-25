using System;
using System.Collections.Generic;
using System.Linq;
using Deployment.Common;
using Deployment.Common.Logging;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.Services
{
    public class DeploymentFilterService : IDeploymentFilterService
    {
        private readonly IDeploymentLogger _logger;
        public DeploymentFilterService(IDeploymentLogger logger = null)
        {
            _logger = logger;
        }

        public Deployment FilterByMachine(Deployment source, IList<string> machines)
        {
            if (machines.IsNullOrEmpty())
                return source;

            _logger?.WriteLine($"Appling machine filtering by {machines.Count} machine(s):");

            machines.ForEach(m => _logger?.WriteLine($"Machine - {m}"));

            var deployment = new Deployment(source);
            var filtered =
                source.Machines.Where(
                    m => machines.Any(mx => mx.Equals(m.Name, StringComparison.InvariantCultureIgnoreCase)));
            deployment.Machines.AddRange(filtered);
            return deployment;
        }
        public Deployment FilterByGroup(Deployment source, GroupFilters groupFilters)
        {
            if (groupFilters == null || (groupFilters.IncludeGroups.Count == 0 && groupFilters.ExcludeGroups.Count == 0))
                return source;

            _logger?.WriteLine("Applying group filtering to deployment:");
            groupFilters.IncludeGroups.ForEach(g => _logger?.WriteLine($"Include Group - {g}"));
            groupFilters.ExcludeGroups.ForEach(g => _logger?.WriteLine($"Exclude Group - {g}"));

            var deployment = new Deployment(source);
            var machines = source.Machines.Select(m =>
            {
                var machine = new Machine(m);
                var includeRoles = groupFilters.IncludeGroups.Count == 0
                    ? m.AllRoles()
                    : m.AllRoles().Where(r => r.Groups.Intersect(groupFilters.IncludeGroups).Any() || r.Groups.Any(g => g.Equals("always", StringComparison.InvariantCultureIgnoreCase)));
                var excludeRoles = m.AllRoles().Where(r => r.Groups.Intersect(groupFilters.ExcludeGroups).Any());
                var rolesToAdd = includeRoles.Except(excludeRoles);
                machine.AddRoles(rolesToAdd);
                return machine;
            });

            deployment.Machines.AddRange(machines.Where(m => m.AllRoles().Any()));
            deployment.CommonRoleFiles.AddRange(source.CommonRoleFiles);
            deployment.CustomTests.AddRange(source.CustomTests);
            return deployment;
        }

        public Deployment ProcessDatabaseInstances(Deployment deployment)
        {
            _logger?.WriteLine("Applying Sql database instances.");
            deployment.Machines.Where(m => m.DatabaseRoles.Any()).ForEach(machine => ProcessDatabaseInstances(deployment, machine));

            return deployment;
        }

        private void ProcessDatabaseInstances(Deployment deployment, Machine machine)
        {
            foreach (var role in machine.DatabaseRoles.Cast<DatabaseDeploy>())
            {
                var instance = deployment.AddSqlInstance(new SqlInstance(machine.Name, role.DatabaseInstance));
                instance.AddDatabaseRole(role);
            }
        }
    }
}