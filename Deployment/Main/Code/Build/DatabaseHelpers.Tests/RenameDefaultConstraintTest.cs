using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class RenameDefaultConstraintTest : BaseDeploymentHelperTest
    {
        public RenameDefaultConstraintTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.SpRenameWrapper);
            DeploymentHelperTestFiles.Add(TestFileName.RenameDefaultConstraint);
        }

        [TestMethod]
        [TestCategory("SQL")]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.SpRenameWrapper)]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.RenameDefaultConstraint)]
        public void ConstraintIsRenamed()
        {   
            string defaultConstraintNameToBe = "DefaultConstraintNameToBe";
            string paramName = "@exists";
            string sql =
                string.Format(
                    @"
                    if exists ( select 1 from sys.default_constraints where name = '{4}')
                    begin
                        raiserror('The constraint [{4}] exists and must not for the test ', 16,1)
                    end

                    declare {0} bit = 0; 
                    exec #RenameDefaultConstraint '{1}', '{2}', '{3}', {4} 

                    if exists ( select 1 from sys.default_constraints where name = '{4}')
                    begin
                        set {0} = 1
                    end
",
                    paramName, TableSchemaName, TableName, DefaultConstraintColumnName, defaultConstraintNameToBe);

            CreateATable();
            
            bool constraintWasRenamed = ExecuteSqlGetBoolean(sql, paramName);

            Assert.IsTrue(constraintWasRenamed);
        }
    }
}