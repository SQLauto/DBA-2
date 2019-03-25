using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class CreateDummyTriggerIfNotExistsTest : BaseDeploymentHelperTest
    {
        public CreateDummyTriggerIfNotExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.TableExists);
            DeploymentHelperTestFiles.Add(TestFileName.CreateDummyTriggerIfNotExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.CreateDummyTriggerIfNotExists)]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.TableExists)]
        public void CreatesDummyTriggerIfNotExists()
        {
            ExampleTriggerDelete();

            string paramName = "@exists";
            string sql = string.Format(@"declare {3} bit = 0; 
                                        if exists (select 1 from sys.triggers tr inner join 
                                                        sys.tables t on 
	                                                        t.object_id = tr.parent_id
                                                        inner join sys.schemas sc on
	                                                        t.schema_id = sc.schema_id
                                                        where
                                                            t.name = '{1}' and
                                                        sc.name = '{0}' and
                                                        tr.name = '{2}'
            
                                                        )
                            begin
                                raiserror ('Trigger exists and must not for test', 16,1)
                            end 
                    
                            exec #CreateDummyTriggerIfNotExists '{0}', '{1}', '{2}'
                            
                            if exists (select 1 from sys.triggers tr inner join 
                                                        sys.tables t on 
	                                                        t.object_id = tr.parent_id
                                                        inner join sys.schemas sc on
	                                                        t.schema_id = sc.schema_id
                                                        where
                                                            t.name = '{1}' and
                                                        sc.name = '{0}' and
                                                        tr.name = '{2}'
            
                                                        )
                            begin
                                set {3} = 1
                            end

                            ", TableSchemaName, TableName, InsertTriggerName, paramName);
            
            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.CreateDummyTriggerIfNotExists)]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.TableExists)]
        public void AltersTriggerToDummyTriggerIfExists()
        {
            ExampleTriggerCreate();

            string paramName = "@exists";
            string sql = string.Format(@"declare {3} bit = 0; 
                                        if not exists (select 1 from sys.triggers tr inner join 
                                                        sys.tables t on 
	                                                        t.object_id = tr.parent_id
                                                        inner join sys.schemas sc on
	                                                        t.schema_id = sc.schema_id
                                                        where
                                                            t.name = '{1}' and
                                                        sc.name = '{0}' and
                                                        tr.name = '{2}' and
                                                        OBJECT_DEFINITION(tr.object_id) like '%{4}%'
                                                        )
                            begin
                                raiserror ('Trigger does not exist and must for test', 16,1)
                            end 
                    
                            exec #CreateDummyTriggerIfNotExists '{0}', '{1}', '{2}'
                            
                            if exists (select 1 from sys.triggers tr inner join 
                                                        sys.tables t on 
	                                                        t.object_id = tr.parent_id
                                                        inner join sys.schemas sc on
	                                                        t.schema_id = sc.schema_id
                                                        where
                                                            t.name = '{1}' and
                                                        sc.name = '{0}' and
                                                        tr.name = '{2}' and
                                                        OBJECT_DEFINITION(tr.object_id) not like '%{4}%'
                                                        )
                            begin
                                set {3} = 1
                            end

                            ", TableSchemaName, TableName, InsertTriggerName, paramName, InsertTriggerContent);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }
         
    }
}