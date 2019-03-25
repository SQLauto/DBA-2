using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class DropTriggerIfItExistsTest : BaseDeploymentHelperTest
    {
        public DropTriggerIfItExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.DropTriggerIfExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.DropTriggerIfExists)]
        public void DropsExistingTrigger()
        {
            ExampleTriggerCreate();

            string paramName = "@exists";
            string sql =
                string.Format(
                    @"declare {0} bit = 0; 
                        if not exists (select 1 from sys.triggers tr inner join 
                                                        sys.tables t on 
	                                                        t.object_id = tr.parent_id
                                                        inner join sys.schemas sc on
	                                                        t.schema_id = sc.schema_id
                                                        where
                                                            t.name = '{2}' and
                                                        sc.name = '{1}' and
                                                        tr.name = '{3}')
                        begin
                            raiserror ('Trigger does not exist and must for test', 16,1)
                        end 
                        
                        exec #DropTriggerIfExists '{1}', '{3}'
                     
                        if not exists ( select 1 from sys.triggers tr inner join 
                                                        sys.tables t on 
	                                                        t.object_id = tr.parent_id
                                                        inner join sys.schemas sc on
	                                                        t.schema_id = sc.schema_id
                                                        where
                                                            t.name = '{2}' and
                                                        sc.name = '{1}' and
                                                        tr.name = '{3}')
                        begin
                           set {0} = 1;
                        end
                    ",
                    paramName, TableSchemaName, TableName, InsertTriggerName);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.DropTriggerIfExists)]
        public void DoesNotThrowExceptionWhenCalledForNonExistantTrigger()
        {
            ExampleTriggerDelete();

            string paramName = "@exists";
            string sql =
                string.Format(
                    @"declare {0} bit = 0; 
                       if exists ( select 1 from sys.triggers tr inner join 
                                                        sys.tables t on 
	                                                        t.object_id = tr.parent_id
                                                        inner join sys.schemas sc on
	                                                        t.schema_id = sc.schema_id
                                                        where
                                                        sc.name = '{1}' and
                                                        tr.name = '{2}')
                        begin
                            raiserror ('Synonym does exist and must not for test', 16,1)
                        end                                           

                        exec #DropTriggerIfExists '{1}', '{2}'
                     
                        if not exists ( select 1 from sys.triggers tr inner join 
                                                        sys.tables t on 
	                                                        t.object_id = tr.parent_id
                                                        inner join sys.schemas sc on
	                                                        t.schema_id = sc.schema_id
                                                        where
                                                        sc.name = '{1}' and
                                                        tr.name = '{2}')
                        begin
                           set {0} = 1;
                        end
                    ",
                    paramName, SynonymSchema, SynonymName);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }
    }
}