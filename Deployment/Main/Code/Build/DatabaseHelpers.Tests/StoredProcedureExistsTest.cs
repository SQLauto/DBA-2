using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class StoredProcedureExistsTest : BaseDeploymentHelperTest
    {
        public StoredProcedureExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.StoredProcedureExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.StoredProcedureExists)]
        public void SprocExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #StoredProcedureExists '{1}', '{2}', {0} out;",
                    paramName, StoredProcedureSchema, StoredProcedureName);

            ExampleStoredProcedureCreate();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.StoredProcedureExists)]
        public void SprocDoesNotExist()
        {
            string name = "Random" + Guid.NewGuid().ToString();
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #StoredProcedureExists '{1}', '{2}', {0} out;",
                    paramName, StoredProcedureSchema, name);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }
    }
}