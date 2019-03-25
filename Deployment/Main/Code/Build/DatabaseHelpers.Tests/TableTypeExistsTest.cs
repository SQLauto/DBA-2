using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class TableTypeExistsTest : BaseDeploymentHelperTest
    {
        public TableTypeExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.TableTypeExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.TableTypeExists)]
        public void TableTypeExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #TableTypeExists '{1}', '{2}', {0} out;",
                    paramName, TableTypeSchema, TableTypeName);

            ExampleTableTypeCreate();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.TableTypeExists)]
        public void TableTypeDoesNotExist()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #TableTypeExists '{1}', '{2}', {0} out;",
                    paramName, TableTypeSchema, TableTypeName);

            ExampleTableTypeDelete();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }
    }
}