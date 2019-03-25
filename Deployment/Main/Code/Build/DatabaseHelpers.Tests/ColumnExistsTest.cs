using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class ColumnExistsTest : BaseDeploymentHelperTest
    {
         public ColumnExistsTest()
         {
             DeploymentHelperTestFiles.Add(TestFileName.ColumnExists);
         }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ColumnExists)]
        public void ColumnExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #ColumnExists '{1}', '{2}', '{3}', {0} out",
                    paramName, TableSchemaName, TableName, NotNullableColumnName);

            CreateATable();

            bool columnExists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(columnExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ColumnExists)]
        public void ColumnDoesNotExist()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #ColumnExists '{1}', '{2}', '{3}', {0} out",
                    paramName, TableSchemaName, TableName, "RandomNoneExistingColumnName");

            CreateATable();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        } 
    }
}