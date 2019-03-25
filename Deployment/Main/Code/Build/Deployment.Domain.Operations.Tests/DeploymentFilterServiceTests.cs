using Deployment.Domain.Operations.Services;
using Deployment.Domain.Roles;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class DeploymentFilterServiceTests : BaseTest
    {
        public TestContext TestContext { get; set; }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("DeploymentFilterService")]
        public void TestGeneratesNoSqlInstances()
        {
            //arrange
            var logger = new TestContextLogger(TestContext);
            var deploymentFilterService = new DeploymentFilterService(logger);

            var deployment = new Deployment();

            for (var i = 0; i < 3; i++)
            {
                var machine = new Machine
                {
                    Name = i.ToString()
                };

                deployment.Machines.Add(machine);
            }

            var dbMachine = deployment.Machines[0];

            for (var i = 0; i < 4; i++)
            {
                var role = new MsiDeploy
                {
                    Name = i.ToString(),
                    Include = string.Concat("Include", i),
                };

                dbMachine.AddRole(role);
            }

            //act
            deployment = deploymentFilterService.ProcessDatabaseInstances(deployment);

            //assert
            Assert.AreEqual(0, deployment.SqlInstances.Count);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("DeploymentFilterService")]
        public void TestGeneratesSqlInstances()
        {
            //arrange
            var logger = new TestContextLogger(TestContext);
            var deploymentFilterService = new DeploymentFilterService(logger);

            var deployment = new Deployment();

            for (var i = 0; i < 3; i++)
            {
                var machine = new Machine
                {
                    Name = i.ToString()
                };

                deployment.Machines.Add(machine);
            }

            var dbMachine = deployment.Machines[0];

            for (var i = 0; i < 4; i++)
            {
                var role = new DatabaseDeploy
                {
                    TargetDatabase = string.Concat("DB", i),
                    Name = i.ToString(),
                    Include = string.Concat("Include", i),
                    DatabaseInstance = i % 2 == 0 ? "1" : "2"
                };

                dbMachine.AddRole(role);
            }

            //act
            deployment = deploymentFilterService.ProcessDatabaseInstances(deployment);

            //assert
            Assert.AreEqual(2, deployment.SqlInstances.Count);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("DeploymentFilterService")]
        public void TestSqlInstancesAreCleared()
        {
            //arrange
            var logger = new TestContextLogger(TestContext);
            var deploymentFilterService = new DeploymentFilterService(logger);

            var deployment = new Deployment();

            for (var i = 0; i < 3; i++)
            {
                var machine = new Machine
                {
                    Name = i.ToString()
                };

                deployment.Machines.Add(machine);
            }

            var dbMachine = deployment.Machines[0];

            for (var i = 0; i < 4; i++)
            {
                var role = new DatabaseDeploy
                {
                    TargetDatabase = string.Concat("DB", i),
                    Name = i.ToString(),
                    Include = string.Concat("Include", i),
                    DatabaseInstance = i % 2 == 0 ? "1" : "2"
                };

                dbMachine.AddRole(role);
            }

            //act
            deployment = deploymentFilterService.ProcessDatabaseInstances(deployment);

            //assert
            Assert.AreEqual(2, deployment.SqlInstances.Count);

            deployment.ClearSqlInstances();

            Assert.AreEqual(0, deployment.SqlInstances.Count);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("DeploymentFilterService")]
        public void TestSqlInstanceRolesAreUniqueForInstance()
        {
            //arrange
            var logger = new TestContextLogger(TestContext);
            var deploymentFilterService = new DeploymentFilterService(logger);

            var deployment = new Deployment();

            for (var i = 0; i < 3; i++)
            {
                var machine = new Machine
                {
                    Name = i.ToString()
                };

                deployment.Machines.Add(machine);
            }

            var dbMachine = deployment.Machines[0];

            for (var i = 0; i < 3; i++)
            {
                var role = new DatabaseDeploy
                {
                    TargetDatabase = "DB1",
                    Name = "Name",
                    Include = string.Concat("Include", i),
                    DatabaseInstance = "1"
                };

                dbMachine.AddRole(role);
            }

            for (var i = 0; i < 3; i++)
            {
                var role = new DatabaseDeploy
                {
                    TargetDatabase = "DB2",
                    Name = "Name",
                    Include = string.Concat("Include", i),
                    DatabaseInstance = "1"
                };

                dbMachine.AddRole(role);
            }

            var repeatedRole = new DatabaseDeploy
            {
                TargetDatabase = "DB2",
                Name = "Name",
                Include = string.Concat("Include", 1),
                DatabaseInstance = "1"
            };

            //repeated role should not get added as not unique for a given instance/database
            dbMachine.AddRole(repeatedRole);

            //act
            deployment = deploymentFilterService.ProcessDatabaseInstances(deployment);

            //assert
            Assert.AreEqual(1, deployment.SqlInstances.Count);
            Assert.AreEqual(6, deployment.SqlInstances[0].DatabaseRoles.Count);
        }
    }
}