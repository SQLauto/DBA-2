using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class GetColumnMaxLengthTest : BaseDeploymentHelperTest
    {
        public GetColumnMaxLengthTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.GetColumnMaxLength);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.GetColumnMaxLength)]
        public void MaxLengthColumnResultIsCorrect()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"declare {0} bit = 0; 
                      declare @length smallint;
                    exec #GetColumnMaxLength '{1}', '{2}', {3},  @length out
                    if (@length = {4})
                    begin
                       set {0} = 1
                    end
",
                    paramName, TableSchemaName, TableName, MaxLengthColumnName, ColumnMaxLength);

            CreateATable();

            bool lengthIsCorrect = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(lengthIsCorrect);
        }
    }
}