using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class ColumnExistsAndIsNullableTest : BaseDeploymentHelperTest
    {
        public ColumnExistsAndIsNullableTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.ColumnExistsAndIsNullable);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ColumnExistsAndIsNullable)]
        public void ColumnExistsAndIsNotNull()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #ColumnExistsAndIsNullable '{1}', '{2}', '{3}', {0} out",
                    paramName, TableSchemaName, TableName, NotNullableColumnName);

            CreateATable();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ColumnExistsAndIsNullable)]
        public void ColumnExistsAndIsNull()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #ColumnExistsAndIsNullable '{1}', '{2}', '{3}', {0} out",
                    paramName, TableSchemaName, TableName, NullableColumnName);

            CreateATable();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        } 
    }
}