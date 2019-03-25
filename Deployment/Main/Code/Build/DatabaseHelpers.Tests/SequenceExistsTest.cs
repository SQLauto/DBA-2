using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class SequenceExistsTest : BaseDeploymentHelperTest
    {
        public SequenceExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.SequenceExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.SequenceExists)]
        public void SequenceExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #SequenceExists '{1}',  '{2}', {0} out",
                    paramName, SequenceSchema, SequenceName);

            ExampleSequenceCreate();
            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.SequenceExists)]
        public void SequenceNotExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #SequenceExists '{1}', '{2}', {0} out",
                    paramName, SequenceSchema, SequenceName);

            ExampleSequenceDelete();
            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }
    }
}