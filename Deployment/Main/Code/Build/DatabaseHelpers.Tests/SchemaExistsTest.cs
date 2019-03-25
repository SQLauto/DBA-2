using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class SchemaExistsTest : BaseDeploymentHelperTest
    {

        public SchemaExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.SchemaExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.SchemaExists)]
        public void SchemaExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #SchemaExists '{1}',  {0} out",
                    paramName, "dbo");


            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.SchemaExists)]
        public void SchemaNotExists()
        {
            string name = "Random" + Guid.NewGuid().ToString();
            string paramName = "@exists";
            string sql =
                string.Format(
                    "declare {0} bit = 0; exec #SchemaExists '{1}', {0} out",
                    paramName, name);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }
    }
}