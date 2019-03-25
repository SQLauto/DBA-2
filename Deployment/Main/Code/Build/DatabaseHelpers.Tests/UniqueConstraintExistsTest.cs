using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class UniqueConstraintExistsTest : BaseDeploymentHelperTest
    {
        public UniqueConstraintExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.UniqueConstraintExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.UniqueConstraintExists)]
        public void UniqueConstraintExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #UniqueConstraintExists '{1}', '{2}', '{3}',  {0} out;",
                    paramName, TableSchemaName, TableName, UniqueConstraintName);

            CreateATable();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.UniqueConstraintExists)]
        public void UniqueConstraintDoesNotExist()
        {
            string name = "Random" + Guid.NewGuid().ToString();
            string paramName = "@exists";
            string sql =
               string.Format(
                   @"
                     declare {0} bit = 0;
                    exec #UniqueConstraintExists '{1}', '{2}', '{3}',  {0} out;",
                   paramName, TableSchemaName, TableName, name);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }
    }
}