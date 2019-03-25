using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class CreateDummyViewIfNotExistsTest : BaseDeploymentHelperTest
    {

        public CreateDummyViewIfNotExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.CreateDummyViewIfNotExists);    
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.CreateDummyViewIfNotExists)]
        public void CreatesDummyViewIfNotExists()
        {
            ExampleViewDeleteIfExists();

            string paramName = "@exists";
            string sql =
                string.Format(
                    @"declare {0} bit = 0; 
                        if exists ( select 1 from sys.views v inner join sys.schemas sc on
                                                    sc.schema_id = v.schema_id where sc.name = '{1}' 
                                                    and v.name = '{2}') 
                        begin
                            raiserror ('View exists and must not for test', 16,1)
                        end 
                    
                        exec #CreateDummyViewIfNotExists '{1}', '{2}'
                     
                        if exists ( select 1 from sys.Views v inner join sys.schemas sc on
                                                    sc.schema_id = v.schema_id where sc.name = '{1}' 
                                                    and v.name = '{2}') 
                        begin
                           set {0} = 1;
                        end
                    ",
                    paramName, ViewSchema, ViewName);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.CreateDummyViewIfNotExists)]
        public void AltersExistingViewToDummyViewDefinitionIfExists()
        {
            ExampleViewDeleteIfExists();

            string paramName = "@exists";
            string sql =
                string.Format(
                    @"declare {0} bit = 0; 
                        if exists ( select 1 from sys.views v inner join sys.schemas sc on
                                                    sc.schema_id = v.schema_id where sc.name = '{1}' 
                                                    and v.name = '{2}') 
                        begin
                            raiserror ('View exists and must not for test', 16,1)
                        end 
                        
                        exec('create view {1}.{2} as {3} ;')
                    
                        exec #CreateDummyViewIfNotExists '{1}', '{2}'
                     
                        if exists ( select 1 from sys.Views v inner join sys.schemas sc on
                                                    sc.schema_id = v.schema_id where sc.name = '{1}' 
                                                    and v.name = '{2}'
                                                    and object_definition(v.Object_id) not like '%{3}%'
                                    ) 
                        begin
                           set {0} = 1;
                        end
                    ",
                    paramName, ViewSchema, ViewName, ViewContent);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }
    }
}