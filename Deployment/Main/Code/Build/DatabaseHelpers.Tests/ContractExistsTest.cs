using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class ContractExistsTest : BaseDeploymentHelperTest
    {
        public ContractExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.ContractExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ContractExists)]
        public void ContractExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #ContractExists '{1}', {0} out",
                    paramName, ServiceContractName);

            CreateServiceBrokerArtifacts();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ContractExists)]
        public void ContractDoesNotExist()
        {
            string paramName = "@exists";
            string randomName = CreateARandomName();
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #ContractExists '{1}', {0} out",
                    paramName, randomName);

            CreateServiceBrokerArtifacts();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }
    }
}