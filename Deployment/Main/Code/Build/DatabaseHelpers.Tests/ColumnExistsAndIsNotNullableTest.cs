using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class ColumnExistsAndIsNotNullableTest : BaseDeploymentHelperTest
    {
        public ColumnExistsAndIsNotNullableTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.ColumnExistsAndIsNotNullable);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ColumnExistsAndIsNotNullable)]
        public void ColumnExistsAndIsNotNull()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #ColumnExistsAndIsNotNullable '{1}', '{2}', '{3}', {0} out",
                    paramName, TableSchemaName, TableName, NotNullableColumnName);

            CreateATable();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ColumnExistsAndIsNotNullable)]
        public void ColumnExistsAndIsNull()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #ColumnExistsAndIsNotNullable '{1}', '{2}', '{3}', {0} out",
                    paramName, TableSchemaName, TableName, NullableColumnName);

            CreateATable();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }
    }
}