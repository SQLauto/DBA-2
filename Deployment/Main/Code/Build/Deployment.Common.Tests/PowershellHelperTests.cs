using System.Management.Automation;
using Deployment.Common.Helpers;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Deployment.Common.Tests
{
    [TestClass]
    public class PowershellHelperTests
    {
        public TestContext TestContext { get; set; }

        //[ClassInitialize]
        //public static void ClassInitialise(TestContext context)
        //{
        //    File.Copy(Path.Combine(context.TestDeploymentDir, "PowershellTest.ps1"),
        //        Path.Combine(context.TestDeploymentDir, "Scripts", "PowershellTest.ps1"),
        //        true);
        //}

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        public void TestCanInvokePowershellText()
        {
            var helper = new PowershellHelper();

            var script = "Get-Verb";

            var result = helper.InvokeCommand(script);

            Assert.IsNotNull(result);
            Assert.IsTrue(result.Count > 0);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [ExpectedException(typeof(CommandNotFoundException))]
        public void TestThrowsForInvalidCommand()
        {
            var helper = new PowershellHelper();

            var script = "Get-Stuff";

            var result = helper.InvokeCommand(script);
        }
    }
}