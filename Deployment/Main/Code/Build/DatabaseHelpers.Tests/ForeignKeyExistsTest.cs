using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class ForeignKeyExistsTest : BaseDeploymentHelperTest
    {
        public ForeignKeyExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.ForeignKeyExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ForeignKeyExists)]
        public void ForeignKeyExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #ForeignKeyExists '{1}', {0} out",
                    paramName, ForeignKeyName);

            CreateATable();

            bool tableExists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(tableExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ForeignKeyExists)]
        public void ForeignKeyNotExists()
        {
            string foreignKeyName = "Random" + Guid.NewGuid().ToString();
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #ForeignKeyExists '{1}', {0} out",
                    paramName, foreignKeyName);

            bool tableExists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(tableExists);
        }
         
    }
}