using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class SynonymExistsTest : BaseDeploymentHelperTest
    {
        public SynonymExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.SynonymExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.SynonymExists)]
        public void SynonymExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #SynonymExists '{1}', '{2}', {0} out;",
                    paramName, SynonymSchema, SynonymName);

            ExampleSynonymCreate();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.SynonymExists)]
        public void SynonymDoesNotExist()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #SynonymExists '{1}', '{2}', {0} out;",
                    paramName, SynonymSchema, SynonymName);
            
            ExampleSynonymDelete();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }
    }
}