using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class TableLockEscalationTest : BaseDeploymentHelperTest
    {
        public TableLockEscalationTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.TableLockEscalationExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.TableLockEscalationExists)]
        public void TableLockEscalationExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #TableLockEscalationExists '{1}', '{2}', '{3}',  {0} out",
                    paramName, TableSchemaName, TableName, TableLockEscalationType);

            CreateATable();

            bool tableExists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(tableExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.TableLockEscalationExists)]
        public void TableLockEscalationNotExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #TableLockEscalationExists '{1}', '{2}', '{3}',  {0} out",
                    paramName, TableSchemaName, TableName, TableLockEscalationTypeForNegativeTesting);

            bool tableExists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(tableExists);
        }
    }
}