using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class ServiceExistsTest : BaseDeploymentHelperTest
    {
        public ServiceExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.ServiceExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ServiceExists)]
        public void ServiceExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #ServiceExists '{1}',  {0} out",
                    paramName, ServiceName);

            CreateServiceBrokerArtifacts();
            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ServiceExists)]
        public void ServiceNotExists()
        {
            string name = "Random" + Guid.NewGuid().ToString();
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #ServiceExists '{1}', {0} out",
                    paramName, name);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }
    }
}