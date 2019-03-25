using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class DropSynonymIfExistsTest : BaseDeploymentHelperTest
    {
        public DropSynonymIfExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.SynonymExists);
            DeploymentHelperTestFiles.Add(TestFileName.DropSynonymIfExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.SynonymExists)]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.DropSynonymIfExists)]
        public void DropsExistingSynonym()
        {
            ExampleSynonymCreate();

            string paramName = "@exists";
            string sql =
                string.Format(
                    @"declare {0} bit = 0; 
                        if not exists ( select 1 from sys.synonyms s inner join sys.schemas sc on
                                                    sc.schema_id = s.schema_id where sc.name = '{1}' 
                                                    and s.name = '{2}')
                        begin
                            raiserror ('Synonym does not exist and must for test', 16,1)
                        end 
                        
                        exec #DropSynonymIfExists '{1}', '{2}'
                     
                        if not exists ( select 1 from sys.synonyms s inner join sys.schemas sc on
                                                    sc.schema_id = s.schema_id where sc.name = '{1}' 
                                                    and s.name = '{2}')
                        begin
                           set {0} = 1;
                        end
                    ",
                    paramName, SynonymSchema, SynonymName);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.SynonymExists)]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.DropSynonymIfExists)]
        public void DoesNotThrowExceptionWhenCalledForNonExistantSynonym()
        {
            ExampleSynonymDelete();

            string paramName = "@exists";
            string sql =
                string.Format(
                    @"declare {0} bit = 0; 
                       if exists ( select 1 from sys.synonyms s inner join sys.schemas sc on
                                                    sc.schema_id = s.schema_id where sc.name = '{1}' 
                                                    and s.name = '{2}')
                        begin
                            raiserror ('Synonym does exist and must not for test', 16,1)
                        end                                           

                        exec #DropSynonymIfExists '{1}', '{2}'
                     
                        if not exists ( select 1 from sys.synonyms f inner join sys.schemas sc on
                                                    sc.schema_id = f.schema_id where sc.name = '{1}' 
                                                    and f.name = '{2}')
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