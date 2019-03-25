using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class MessageTypeExistsTest : BaseDeploymentHelperTest
    {
        public MessageTypeExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.MessageTypeExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.MessageTypeExists)]
        public void MessageTypeExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #MessageTypeExists '{1}', {0} out",
                    paramName, ServiceMessageTypeName);

            CreateServiceBrokerArtifacts();

            bool messageTypeExists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(messageTypeExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.MessageTypeExists)]
        public void MessageTypeNotExists()
        {
            string messageTypeName = "Random" + Guid.NewGuid().ToString();
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #MessageTypeExists '{1}', {0} out",
                    paramName, messageTypeName);

            bool messageTypeExists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(messageTypeExists);
        }
    }
}