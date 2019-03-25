using System.IO;
using Deployment.Domain.Operations.Services;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class PathBuilderTests
    {
        public TestContext TestContext { get; set; }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        public void TestFindsParametersDirectory()
        {
            var builder = new PackagePathBuilder(TestContext.TestDeploymentDir) { IsLocalDebugMode = true };

            var directory = builder.ParametersRelativeDirectory;

            Assert.IsFalse(string.IsNullOrWhiteSpace(directory));
            Assert.IsTrue(Directory.Exists(directory));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        public void TestFindsAccountsDirectory()
        {
            var builder = new PackagePathBuilder(TestContext.TestDeploymentDir) { IsLocalDebugMode = true };

            var directory = builder.AccountsRelativeDirectory;

            Assert.IsFalse(string.IsNullOrWhiteSpace(directory));
            Assert.IsTrue(Directory.Exists(directory));
        }
    }
}