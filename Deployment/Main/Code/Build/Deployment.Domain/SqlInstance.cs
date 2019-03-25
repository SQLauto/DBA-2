using System;
using System.Collections.Generic;
using System.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain
{
    public class SqlInstance : IEquatable<SqlInstance>
    {
        private readonly HashSet<IDatabaseRole> _databaseRoles;

        public SqlInstance()
        {
            _databaseRoles = new HashSet<IDatabaseRole>();
        }

        public SqlInstance(string machineName, string instanceName = null) : this()
        {
            MachineName = machineName;
            InstanceName = instanceName;
        }

        public bool AddDatabaseRole(IDatabaseRole databaseRole)
        {
            return _databaseRoles.Add(databaseRole);
        }

        public string MachineName { get; }
        public string InstanceName { get; }
        public IReadOnlyList<IDatabaseRole> DatabaseRoles => _databaseRoles.ToList();

        public string DisplayName => string.Concat(MachineName,
            string.IsNullOrWhiteSpace(InstanceName) ? string.Empty : ".", InstanceName ?? string.Empty);

        public override string ToString()
        {
            return DisplayName;
        }

        public bool Equals(SqlInstance other)
        {
            if (ReferenceEquals(null, other)) return false;
            if (ReferenceEquals(this, other)) return true;
            return string.Equals(MachineName, other.MachineName, StringComparison.InvariantCultureIgnoreCase)
                   && string.Equals(InstanceName, other.InstanceName, StringComparison.InvariantCultureIgnoreCase);
        }

        public override bool Equals(object obj)
        {
            if (ReferenceEquals(null, obj)) return false;
            if (ReferenceEquals(this, obj)) return true;
            return obj.GetType() == GetType() && Equals((SqlInstance)obj);
        }

        public override int GetHashCode()
        {
            unchecked // Overflow is fine, just wrap
            {
                var hash = 17;
                hash = hash * 23 + (string.IsNullOrEmpty(MachineName) ? 0 : MachineName.ToLowerInvariant().GetHashCode());
                hash = hash * 23 + (string.IsNullOrEmpty(InstanceName) ? 0 : InstanceName.ToLowerInvariant().GetHashCode());
                return hash;
            }
        }
    }
}