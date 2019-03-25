using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class XmlSchemaCollectionExistsTest : BaseDeploymentHelperTest
    {
        public XmlSchemaCollectionExistsTest()
        {
            DeploymentHelperTestFiles.Add("XmlSchemaCollectionExistsTemporaryStoredProcedure.sql");
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.XmlSchemaCollectionExists)]
        public void XmlSchemaCollectionExists()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #XmlSchemaCollectionExists '{1}', '{2}', {0} out;",
                    paramName, XmlSchemaCollectionSchema, XmlSchemaCollectionName);

            ExampleXmlSchemaCollectionCreate();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        public void XmlSchemaCollectionDoesNotExist()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                     declare {0} bit = 0;
                    exec #XmlSchemaCollectionExists '{1}', '{2}', {0} out;",
                    paramName, XmlSchemaCollectionSchema, XmlSchemaCollectionName);

            ExampleXmlSchemaCollectionDelete();

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsFalse(exists);
        }
    }
}