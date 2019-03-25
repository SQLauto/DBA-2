using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class ColumnExistsAndIsAnIdentityTest : BaseDeploymentHelperTest
    {
        public ColumnExistsAndIsAnIdentityTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.ColumnExistsAndIsIdentity);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ColumnExistsAndIsIdentity)]
        public void ColumnExistsAndIsAnIdentity()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #ColumnExistsAndIsIdentity '{1}', '{2}', '{3}', {0} out",
                    paramName, TableSchemaName, TableName, IdentityColumnName);

            CreateATable();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ColumnExistsAndIsIdentity)]
        public void ColumnExistsAndIsNotAnIdentity()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #ColumnExistsAndIsIdentity '{1}', '{2}', '{3}', {0} out",
                    paramName, TableSchemaName, TableName, NullableColumnName);

            CreateATable();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }


    }
}