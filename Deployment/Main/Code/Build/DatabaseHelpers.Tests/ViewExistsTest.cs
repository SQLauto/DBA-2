using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class ViewExistsTest : BaseDeploymentHelperTest
    {
        public ViewExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.ViewExists);   
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ViewExists)]
        public void ViewExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #ViewExists '{1}', '{2}', {0} out;",
                    paramName, ViewSchema, ViewName);

            ExampleViewCreate();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.ViewExists)]
        public void ViewDoesNotExist()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #ViewExists '{1}', '{2}', {0} out;",
                    paramName, ViewSchema, ViewName);

            ExampleViewDeleteIfExists();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }
    }
}