using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class DropSequenceIfExistsTest : BaseDeploymentHelperTest
    {
        public DropSequenceIfExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.SequenceExists);
            DeploymentHelperTestFiles.Add(TestFileName.DropSequenceIfExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.SequenceExists)]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.DropSequenceIfExists)]
        public void DropsExistingSequence()
        {
            ExampleSequenceCreate();

            string paramName = "@exists";
            string sql =
                string.Format(
                    @"declare {0} bit = 0; 
                        if not exists ( select 1 from sys.sequences s inner join sys.schemas sc on
                                                    sc.schema_id = s.schema_id where sc.name = '{1}' 
                                                    and s.name = '{2}')
                        begin
                            raiserror ('Sequence does not exist and must for test', 16,1)
                        end 
                        
                        exec #DropSequenceIfExists '{1}', '{2}'
                     
                        if not exists ( select 1 from sys.sequences s inner join sys.schemas sc on
                                                    sc.schema_id = s.schema_id where sc.name = '{1}' 
                                                    and s.name = '{2}')
                        begin
                           set {0} = 1;
                        end
                    ",
                    paramName, SequenceSchema, SequenceName);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.SequenceExists)]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.DropSequenceIfExists)]
        public void DoesNotThrowExceptionWhenCalledForNonExistantSequence()
        {
            ExampleSequenceDelete();

            string paramName = "@exists";
            string sql =
                string.Format(
                    @"declare {0} bit = 0; 
                       if exists ( select 1 from sys.sequences s inner join sys.schemas sc on
                                                    sc.schema_id = s.schema_id where sc.name = '{1}' 
                                                    and s.name = '{2}')
                        begin
                            raiserror ('Sequence does exist and must not for test', 16,1)
                        end                                           

                        exec #DropSequenceIfExists '{1}', '{2}'
                     
                        if not exists ( select 1 from sys.sequences f inner join sys.schemas sc on
                                                    sc.schema_id = f.schema_id where sc.name = '{1}' 
                                                    and f.name = '{2}')
                        begin
                           set {0} = 1;
                        end
                    ",
                    paramName, SequenceSchema, SequenceName);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }
    }
}