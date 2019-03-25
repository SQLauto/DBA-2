using Deployment.Common.Helpers;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Deployment.Common.Tests
{
    [TestClass]
    public class FileHelperTests
    {
        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileHelper")]
        public void TestsRelativePath()
        {
            var helper = new FileHelper();
            var path1 =
                @"C:\A\B\C\D\E";
            var path2 =
                @"F\G\H";

            var relative = helper.GetRelativePath(path1, path2);

            Assert.IsTrue(relative.Equals(path2, System.StringComparison.CurrentCulture));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileHelper")]
        public void TestsRelativePathWithSpaces()
        {
            var helper = new FileHelper();
            var path1 =
                @"C:\A\B\C\D\E";
            var path2 =
                @"F 1 3\G\H";

            var relative = helper.GetRelativePath(path1, path2);

            Assert.IsTrue(relative.Equals(path2, System.StringComparison.CurrentCulture));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileHelper")]
        public void TestsRelativePathWithVersion()
        {
            var helper = new FileHelper();
            var path1 =
                @"C:\A\B\C\D\E";
            var path2 =
                @"F.1.2.3.4\G\H";

            var relative = helper.GetRelativePath(path1, path2);

            Assert.IsTrue(relative.Equals(path2, System.StringComparison.CurrentCulture));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileHelper")]
        public void TestsFullPath()
        {
            var helper = new FileHelper();
            var path1 =
                @"C:\A\B\C\D\E";
            var path2 =
                @"C:\A\B\C\D\E\F\G\H";

            var relative = helper.GetRelativePath(path1, path2);

            Assert.IsTrue(relative.Equals(@"F\G\H", System.StringComparison.CurrentCulture));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileHelper")]
        public void TestsFullPathWithSpaces()
        {
            var helper = new FileHelper();
            var path1 =
                @"C:\A\B\C\D\E";
            var path2 =
                @"C:\A\B\C\D\E\F 1 2\G\H";

            var relative = helper.GetRelativePath(path1, path2);

            Assert.IsTrue(relative.Equals(@"F 1 2\G\H", System.StringComparison.CurrentCulture));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileHelper")]
        public void TestsFullPathWithVersion()
        {
            var helper = new FileHelper();
            var path1 =
                @"C:\A\B\C\D\E";
            var path2 =
                @"C:\A\B\C\D\E\F.1.2.3.4\G\H";

            var relative = helper.GetRelativePath(path1, path2);

            Assert.IsTrue(relative.Equals(@"F.1.2.3.4\G\H", System.StringComparison.CurrentCulture));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileHelper")]
        public void TestsReturnsFullPathIfNotRelative()
        {
            var helper = new FileHelper();
            var path1 =
                @"C:\A\B\C\D\E";
            var path2 =
                @"D:\X\Y\Z";

            var relative = helper.GetRelativePath(path1, path2);

            Assert.IsTrue(relative.Equals(path2, System.StringComparison.CurrentCulture));
        }
    }
}