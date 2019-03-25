using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public class DropCodeObjectAndReferencedObjectsTest : BaseDeploymentHelperTest
    {
        public DropCodeObjectAndReferencedObjectsTest()
        {
            DeploymentHelperTestFiles.Add(TestFileName.DropCodeObjectAndReferencedObjects);
        }

        [TestMethod]
        [DeploymentItem(DeploymentHelperFolder + @"\" + TestFileName.DropCodeObjectAndReferencedObjects)]
        public void DropsObjectsCorrectly()
        {
            
        }
    }
}