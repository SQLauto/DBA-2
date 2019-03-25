using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class TableExistsTest : BaseDeploymentHelperTest
    {
        public TableExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.TableExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.TableExists)]
        public void TableExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #TableExists '{1}', '{2}',  {0} out",
                    paramName, TableSchemaName, TableName);
            
            CreateATable();

            bool tableExists = ExecuteSqlGetBoolean(sql, paramName);
            
            Assert.IsTrue(tableExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.TableExists)]
        public void TableNotExists()
        {
            string tableName = "Random" + Guid.NewGuid().ToString();
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #TableExists '{1}', '{2}',  {0} out",
                    paramName, TableSchemaName, tableName);

            bool tableExists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(tableExists);
        }
    }
}