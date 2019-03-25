using System;
using System.Collections.Generic;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class DatabaseDeploy : BaseRole, IDatabaseRole
    {
        public DatabaseDeploy()
        {
            EnableAspnetSqlInfo = new EnableAspnetSqlInfo();
            RoleType = "Database Deploy";
        }
        public string TargetDatabase { get; set; }
        public string DatabaseInstance { get; set; }
        public string BaselineDeployment { get; set; }
        public string PreDeployment { get; set; }
        public string PatchDeployment { get; set; }
        public string PostDeployment { get; set; }
        public string FolderPath { get; set; }
        public string PatchDeploymentFolder { get; set; }
        public string PatchFolderFormatStartsWith { get; set; }
        public string UpgradeScript { get; set; }
        public string PreValidationScript { get; set; }
        public string PostValidationScript { get; set; }
        public string PatchLevelDeterminationScript { get; set; }
        public EnableAspnetSqlInfo EnableAspnetSqlInfo { get; set; }
        public SqlTestInfo TestInfo { get; set; }
        public bool IncludeTfsBuild { get; set; }

        public override bool Equals(BaseRole other)
        {
            if (ReferenceEquals(null, other)) return false;
            if (ReferenceEquals(this, other)) return true;

            var dbRole = other as DatabaseDeploy;

            if (dbRole == null)
                return false;

            return Name.Equals(dbRole.Name, StringComparison.InvariantCultureIgnoreCase)
                   && Include.Equals(dbRole.Include, StringComparison.InvariantCultureIgnoreCase)
                   && TargetDatabase.Equals(dbRole.TargetDatabase, StringComparison.InvariantCultureIgnoreCase);
        }

        public override int GetHashCode()
        {
            unchecked // Overflow is fine, just wrap
            {
                var hash = 17;
                hash = hash * 23 + (string.IsNullOrEmpty(Name) ? 0 : Name.ToLowerInvariant().GetHashCode());
                hash = hash * 23 + (string.IsNullOrEmpty(Include) ? 0 : Include.ToLowerInvariant().GetHashCode());
                hash = hash * 23 + (string.IsNullOrEmpty(TargetDatabase) ? 0 : TargetDatabase.ToLowerInvariant().GetHashCode());
                return hash;
            }
        }
    }

    [Serializable]
    public class EnableAspnetSqlInfo
    {
        public EnableAspnetSqlInfo()
        {
            Tables = new List<string>();
        }

        public IList<string> Tables { get; private set; }
    }

    [Serializable]
    public class SqlTestInfo
    {
        [Mandatory]
        public string Sql { get; set; }
        public bool Ignore { get; set; }
        public string UserName { get; set; }
        public string Password { get; set; }
    }
}