using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class IndexExistsTest : BaseDeploymentHelperTest
    {
        public IndexExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.IndexExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.IndexExists)]
        public void IndexExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #IndexExists '{1}',  {0} out",
                    paramName, IndexName);

            CreateATable();

            bool tableExists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(tableExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.IndexExists)]
        public void IndexNotExists()
        {
            string indexName = "Random" + Guid.NewGuid().ToString();
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #IndexExists '{1}', {0} out",
                    paramName, indexName);

            bool indexExists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(indexExists);
        }
         
    }
}