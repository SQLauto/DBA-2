using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class GetColumnTypeTest : BaseDeploymentHelperTest
    {
        public GetColumnTypeTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.GetColumnType);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.GetColumnType)]
        public void ColumnTypeResultIsCorrect()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"declare {0} bit = 0; 
                      declare @columnType varchar(255);
                    exec #GetColumntype '{1}', '{2}', {3},  @columnType out
                    if (@columnType = '{4}')
                    begin
                       set {0} = 1
                    end
",
                    paramName, TableSchemaName, TableName, MaxLengthColumnName, MaxLengthColumnType);

            CreateATable();

            bool typeIsCorrect = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(typeIsCorrect);
        }
    }
}