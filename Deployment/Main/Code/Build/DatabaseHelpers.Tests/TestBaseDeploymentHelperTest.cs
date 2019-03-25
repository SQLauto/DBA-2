using System.Data;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{

    [TestClass]
    public class TestBaseDeploymentHelperTest : BaseDeploymentHelperTest
    {
        public TestBaseDeploymentHelperTest()
        {
            base.DeploymentHelperTestFiles.Add(TestFileName.TableExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.TableExists)]
        public void ConnectionIsOpen()
        {
            Assert.IsTrue(Connection.State == ConnectionState.Open);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.TableExists)]
        public void ExecuteSqlGetBooleanReturnsTrueCorrectly()
        {
            string outputParamName = "@OutputParamName";
            string sql = string.Format("declare {0} bit; set {0} = 1;", outputParamName);
            bool actual = base.ExecuteSqlGetBoolean(sql, outputParamName);

            Assert.IsTrue(actual);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.TableExists)]
        public void ExecuteSqlGetBooleanReturnsFalseCorrectly()
        {
            string outputParamName = "@OutputParamName";
            string sql = string.Format("declare {0} bit; set {0} = 0;", outputParamName);
            bool actual = base.ExecuteSqlGetBoolean(sql, outputParamName);

            Assert.IsFalse(actual);
        }
    }
}