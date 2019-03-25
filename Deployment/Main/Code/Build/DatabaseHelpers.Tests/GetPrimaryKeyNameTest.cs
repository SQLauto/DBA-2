using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class GetPrimaryKeyNameTest : BaseDeploymentHelperTest
    {
        public GetPrimaryKeyNameTest()
        {
            DeploymentHelperTestFiles.Add("GetPrimaryKeyNameTemporaryStoredProcedure.sql");
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.GetPrimaryKeyName)]
        public void PrimaryKeyNameIsCorrect()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"declare {0} bit = 0; 
                      declare @pkName varchar(255);
                    exec #GetPrimaryKeyName '{1}', '{2}',  @pkName out
                    if (@pkName = '{3}')
                    begin
                       set {0} = 1
                    end
",
                    paramName, TableSchemaName, TableName, PrimaryKeyName);

            CreateATable();

            bool typeIsCorrect = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(typeIsCorrect);
        } 
    }
}