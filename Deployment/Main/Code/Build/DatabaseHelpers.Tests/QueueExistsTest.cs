using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class QueueExistsTest : BaseDeploymentHelperTest
    {
        public QueueExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.QueueExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.QueueExists)]
        public void QueueExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #QueueExists '{1}', '{2}', {0} out",
                    paramName, ServiceQueueSchema, ServiceQueueName);

            CreateServiceBrokerArtifacts();

            bool messageTypeExists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(messageTypeExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.QueueExists)]
        public void QueueNotExists()
        {
            string queueName = "Random" + Guid.NewGuid().ToString();
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #QueueExists 'dbo', '{1}', {0} out",
                    paramName, queueName);

            bool queueExists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(queueExists);
        }
    }
}