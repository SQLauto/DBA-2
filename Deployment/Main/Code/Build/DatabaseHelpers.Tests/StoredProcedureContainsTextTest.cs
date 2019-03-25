using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class StoredProcedureContainsTextTest : BaseDeploymentHelperTest
    {
        public StoredProcedureContainsTextTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.StoredProcedureDefinitionContainsText);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.StoredProcedureDefinitionContainsText)]
        public void SprocContainsText()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #StoredProcedureDefinitionContainsText '{1}', '{2}', '{3}', {0} out;",
                    paramName, StoredProcedureSchema, StoredProcedureName, StoredProcedureContent);

            ExampleStoredProcedureCreate();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.StoredProcedureDefinitionContainsText)]
        public void SprocDoesNotContainsText()
        {
            string name = "Random" + Guid.NewGuid().ToString();
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #StoredProcedureDefinitionContainsText '{1}', '{2}', '{3}', {0} out;",
                    paramName, StoredProcedureSchema, name, StoredProcedureContent);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }
    }
}