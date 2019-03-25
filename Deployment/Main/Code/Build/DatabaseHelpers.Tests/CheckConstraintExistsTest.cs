using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class CheckConstraintExistsTest : BaseDeploymentHelperTest
    {
        
        public CheckConstraintExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.CheckConstraintExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.CheckConstraintExists)]
        public void CheckConstraintExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #CheckConstraintExists '{1}', '{2}', '{3}', {0} out",
                    paramName, TableSchemaName, TableName, CheckConstraintName);

            CreateATable();

            bool checkConstraintExists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(checkConstraintExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.CheckConstraintExists)]
        public void CheckConstraintDoesNotExist()
        {
            string paramName = "@exists";
            var checkConstraintName = CheckConstraintName + Guid.NewGuid().ToString();
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #CheckConstraintExists '{1}', '{2}', '{3}', {0} out",
                    paramName, TableSchemaName, TableName, checkConstraintName);

            CreateATable();

            bool checkConstraintExists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(checkConstraintExists);
        }
    }
}