using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class DropFunctionIfExistsTest : BaseDeploymentHelperTest
    {
        public DropFunctionIfExistsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.DropFunctionIfExists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.DropFunctionIfExists)]
        public void DropsExistingFunction()
        {
            ExampleFunctionCreate();

            string paramName = "@exists";
            string sql =
                string.Format(
                    @"declare {0} bit = 0; 
                        if not exists ( select 1 from sys.objects f inner join sys.schemas sc on
                                                    sc.schema_id = f.schema_id where sc.name = '{1}' 
                                                    and f.name = '{2}')
                        begin
                            raiserror ('Function does not exist and must for test', 16,1)
                        end 
                        
                        exec #DropFunctionIfExists '{1}', '{2}'
                     
                        if not exists ( select 1 from sys.objects f inner join sys.schemas sc on
                                                    sc.schema_id = f.schema_id where sc.name = '{1}' 
                                                    and f.name = '{2}')
                        begin
                           set {0} = 1;
                        end
                    ",
                    paramName, FunctionSchema, FunctionName);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.DropFunctionIfExists)]
        public void DoesNotThrowExceptionWhenCalledForNonExistantFunction()
        {
            ExampleFunctionDelete();

            string paramName = "@exists";
            string sql =
                string.Format(
                    @"declare {0} bit = 0; 
                        if exists ( select 1 from sys.objects f inner join sys.schemas sc on
                                                    sc.schema_id = f.schema_id where sc.name = '{1}' 
                                                    and f.name = '{2}')
                        begin
                           raiserror ('Function exists and must not for test', 16,1)
                        end                                               

                        exec #DropFunctionIfExists '{1}', '{2}'
                     
                        if not exists ( select 1 from sys.objects f inner join sys.schemas sc on
                                                    sc.schema_id = f.schema_id where sc.name = '{1}' 
                                                    and f.name = '{2}')
                        begin
                           set {0} = 1;
                        end
                    ",
                    paramName, FunctionSchema, FunctionName);

            bool exists = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(exists);
        }
    }
}