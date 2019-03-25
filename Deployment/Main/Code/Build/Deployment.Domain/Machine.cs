using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain
{
    public class Machine
    {
        public Machine()
        {
            PreRequisites = ImmutableList<IPrerequsiteRole>.Empty;
            PreDeploymentRoles = ImmutableList<IPreDeploymentRole>.Empty;
            DeploymentRoles = ImmutableList<IDeploymentRole>.Empty;
            DatabaseRoles = ImmutableList<IDatabaseRole>.Empty;
            PostDeploymentRoles = ImmutableList<IPostDeploymentRole>.Empty;
            CustomTestRoles = ImmutableList<ICustomTest>.Empty;
        }

        public Machine(Machine machine) : this()
        {
            Id = machine.Id;
            Name = machine.Name;
            ExternalIpAddress = machine.ExternalIpAddress;
            Role = machine.Role;
            DeploymentMachine = machine.DeploymentMachine;
            Cluster = machine.Cluster;
        }

        [Mandatory]
        public string Id { get; set; }
        [Mandatory]
        public string Name { get; set; }
        public string ExternalIpAddress { get; set; }
        public string Role { get; set; }
        public bool DeploymentMachine { get; set; }
        public string Cluster { get; set; }
        public string DeploymentAddress => string.IsNullOrWhiteSpace(ExternalIpAddress) ? Name : ExternalIpAddress;

        public ImmutableList<IPrerequsiteRole> PreRequisites { get; private set; }
        public ImmutableList<IPreDeploymentRole> PreDeploymentRoles { get; private set; }
        public ImmutableList<IDeploymentRole> DeploymentRoles { get; private set; }
        public ImmutableList<IDatabaseRole> DatabaseRoles { get; private set; }
        public ImmutableList<IPostDeploymentRole> PostDeploymentRoles { get; private set; }
        public ImmutableList<ICustomTest> CustomTestRoles { get; private set; }

        public IEnumerable<IBaseRole> AllRoles()
        {
            var roles = new[]
            {
                PreRequisites,
                PreDeploymentRoles,
                DeploymentRoles,
                DatabaseRoles,
                PostDeploymentRoles,
                CustomTestRoles.Cast<IBaseRole>() //forces the whole array to be of type IBaseRole
            };

            //return distinct as roles can live in multiple lists.
            return roles.SelectMany(r => r).Distinct();
        }

        public bool AddRole(IBaseRole role)
        {
            var actionResults = new[]
            {
                AddToList(role, t => PreRequisites = t, PreRequisites)
                , AddToList(role, t => PreDeploymentRoles = t, PreDeploymentRoles)
                , AddToList(role, t => DeploymentRoles = t, DeploymentRoles)
                , AddToList(role, t => DatabaseRoles = t, DatabaseRoles)
                , AddToList(role, t => PostDeploymentRoles = t, PostDeploymentRoles)
                , AddToList(role, t => CustomTestRoles = t, CustomTestRoles)
            };
            return actionResults.Any(x => x);
        }

        public bool AddRoles(IEnumerable<IBaseRole> roles)
        {
            return roles.Aggregate(false, (current, role) =>
                    current | AddRole(role));
        }

        private bool AddToList<T>(IBaseRole role, Action<ImmutableList<T>> setter, ImmutableList<T> roleList)
            where T : class, IBaseRole
        {
            var roleToAdd = role as T;
            if (roleToAdd == null)
                return false;

            // ReSharper disable once RedundantAssignment
            //This is required as it is an immutable list so when you add you get a new list.
            roleList = roleList.Add(roleToAdd);

            setter(roleList);

            return true;
        }
    }
}