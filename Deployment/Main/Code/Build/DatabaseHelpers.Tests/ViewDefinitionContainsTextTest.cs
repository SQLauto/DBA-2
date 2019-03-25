using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class ViewDefinitionContainsTextTest : BaseDeploymentHelperTest
    {
        public ViewDefinitionContainsTextTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.ViewDefinitionContainsText);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ViewDefinitionContainsText)]
        public void ViewContainsText()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #ViewDefinitionContainsText '{1}', '{2}', '{3}', {0} out;",
                    paramName, ViewSchema, ViewName, ViewContent);

            ExampleViewCreate();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ViewDefinitionContainsText)]
        public void ViewDoesNotContainsText()
        {
            string searchText = "Random" + Guid.NewGuid().ToString();
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #ViewDefinitionContainsText '{1}', '{2}', '{3}', {0} out;",
                    paramName, ViewSchema, ViewName, searchText);

            ExampleViewDeleteIfExists();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }
    }
}