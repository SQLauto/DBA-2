using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class CreateDummyStoredProcedureTest : BaseDeploymentHelperTest
    {
        public CreateDummyStoredProcedureTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.CreateDummyStoredProcedureIfNotExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.CreateDummyStoredProcedureIfNotExists)]
        public void CreatesDummyProcIfNotExists()
        {
            ExampleStoredProcedureDeleteIfExists();

            string paramName = "@exists";
            string sql =
                string.Format(
                    @"declare {0} bit = 0; 
                        if exists ( select 1 from sys.procedures p inner join sys.schemas sc on
                                                    sc.schema_id = p.schema_id where sc.name = '{1}' 
                                                    and p.name = '{2}') 
                        begin
                            raiserror ('Sproc exists and must not for test', 16,1)
                        end 
                    
                        exec #CreateDummyStoredProcedureIfNotExists '{1}', '{2}'
                     
                        if exists ( select 1 from sys.procedures p inner join sys.schemas sc on
                                                    sc.schema_id = p.schema_id where sc.name = '{1}' 
                                                    and p.name = '{2}') 
                        begin
                           set {0} = 1;
                        end
                    ",
                    paramName, StoredProcedureSchema, StoredProcedureName);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.CreateDummyStoredProcedureIfNotExists)]
        public void AltersExistingProcedureToDummyProcDefinitionIfExists()
        {
            ExampleStoredProcedureDeleteIfExists();

            string paramName = "@exists";
            string sql =
                string.Format(
                    @"declare {0} bit = 0; 
                        if exists ( select 1 from sys.procedures p inner join sys.schemas sc on
                                                    sc.schema_id = p.schema_id where sc.name = '{1}' 
                                                    and p.name = '{2}') 
                        begin
                            raiserror ('Sproc exists and must not for test', 16,1)
                        end 
                        
                        exec('create procedure {1}.{2} as begin {3} end;')
                    
                        exec #CreateDummyStoredProcedureIfNotExists '{1}', '{2}'
                     
                        if exists ( select 1 from sys.procedures p inner join sys.schemas sc on
                                                    sc.schema_id = p.schema_id where sc.name = '{1}' 
                                                    and p.name = '{2}'
                                                    and object_definition(p.Object_id) not like '%{3}%'
                                    ) 
                        begin
                           set {0} = 1;
                        end
                    ",
                    paramName, StoredProcedureSchema, StoredProcedureName, StoredProcedureContent);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }
    }
}