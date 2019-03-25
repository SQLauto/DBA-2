using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class TriggerExistsTest : BaseDeploymentHelperTest
    {
        public TriggerExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.TriggerExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.TriggerExists)]
        public void TriggerExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #TriggerExists '{1}', {0} out;",
                    paramName, InsertTriggerName);

            ExampleTriggerCreate();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.TriggerExists)]
        public void TriggerDoesNotExist()
        {
            string searchText = "Random" + Guid.NewGuid().ToString();
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #TriggerExists '{1}',  {0} out;",
                    paramName, InsertTriggerName);

            ExampleTriggerDelete();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }
    }
}