using System.Collections.Generic;
using System.Linq;
using Deployment.Domain.Roles;

namespace Deployment.Domain
{
    public class Deployment
    {
        private readonly IList<SqlInstance> _sqlInstances;

        public Deployment()
        {
            Machines = new List<Machine>();
            CommonRoleFiles = new List<string>();
            CustomTests = new List<ICustomTest>();
            PostDeploymentTestIdentity = "DeploymentAccount";
            _sqlInstances = new List<SqlInstance>();
        }

        public Deployment(Deployment deployment) : this()
        {
            Id = deployment.Id;
            Name = deployment.Name;
            Environment = deployment.Environment;
            ProductGroup = deployment.ProductGroup;
            Configuration = deployment.Configuration;
            PostDeploymentTestIdentity = deployment.PostDeploymentTestIdentity;
        }

        public SqlInstance AddSqlInstance(SqlInstance sqlInstance)
        {
            var index = _sqlInstances.IndexOf(sqlInstance);

            if (index > -1)
                return _sqlInstances[index];

            _sqlInstances.Add(sqlInstance);

            return sqlInstance;
        }

        public void ClearSqlInstances()
        {
            _sqlInstances.Clear();
        }

        public string Id { get; set; }
        public string Name { get; set; }
        public string Environment { get; set; }
        public string ProductGroup { get; set; }
        public IList<Machine> Machines { get; }
        public IReadOnlyList<SqlInstance> SqlInstances => _sqlInstances.ToList();
        public string Configuration { get; set; }
        public IList<string> CommonRoleFiles { get; }
        public string PostDeploymentTestIdentity { get; set; }
        public IList<ICustomTest> CustomTests { get; }

    }
}