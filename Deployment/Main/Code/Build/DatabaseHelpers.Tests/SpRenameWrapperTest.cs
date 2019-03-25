using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class SpRenameWrapperTest : BaseDeploymentHelperTest
    {
        public SpRenameWrapperTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.SpRenameWrapper);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.SpRenameWrapper)]
        public void RenameColumn()
        {
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                        if exists (select 1 from sys.tables t inner join sys.schemas sc on
                                    t.schema_id = sc.schema_id 
                                    inner join sys.columns c on c.object_id = t.object_id
                                    where sc.name = '{1}' and
                                    t.name = '{2}' and
                                    c.name = '{4}')
                        begin
                           raiserror('[{1}.{2}.{3}] can  not exist for this test', 16, 1);
                        end;

                    declare {0} bit = 0;
                    declare @message varchar(max);
                    exec #SpRenameWrapper '{1}.{2}.{3}', '{4}', 'column';
                      
                        if exists (select 1 from sys.tables t inner join sys.schemas sc on
                                    t.schema_id = sc.schema_id 
                                    inner join sys.columns c on c.object_id = t.object_id
                                    where sc.name = '{1}' and
                                    t.name = '{2}' and
                                    c.name = '{4}')
                        begin
                           set {0} = 1
                        end;
",
                    paramName, TableSchemaName, TableName, NotNullableColumnName, "RenamedColumnName");

            CreateATable();
            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }
    }
}