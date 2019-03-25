using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class TriggerDefinitionContainsTextTest : BaseDeploymentHelperTest
    {
        public TriggerDefinitionContainsTextTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.TriggerDefinitionContainsText);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.TriggerDefinitionContainsText)]
        public void TriggerDefinitionContainsText()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #TriggerDefinitionContainsText '{1}', '{2}', '{3}', {0} out;",
                    paramName, TableSchemaName, InsertTriggerName, InsertTriggerContent);

            ExampleTriggerCreate();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.TriggerDefinitionContainsText)]
        public void TriggerDefinitionDoesNotContainText()
        {
            string searchText = "Random" + Guid.NewGuid().ToString();
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #TriggerDefinitionContainsText '{1}', '{2}', '{3}', {0} out;",
                    paramName, TableSchemaName, InsertTriggerName, searchText);

            ExampleTriggerCreate();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }
    }
}