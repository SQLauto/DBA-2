using Deployment.Common.Helpers;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Tfl.Deployment.Database.Commands;
using Tfl.Module.Testing;

namespace Tfl.Deployment.Database.Module.Tests
{
    [TestClass]
    public class StartSsisSetupTests
    {
        [TestMethod]
        [TestCategory("StartSsisSetup")]
        [ExpectParameterBindingException(MessagePattern = "ConnectionString")]
        public void TestInvokeWithMissingConnectionStringThrows()
        {
            PsCmdletAssert.Invoke(typeof(StartSsisSetup), new[] { new Parameter("SsisDatabase", "XXX"), new Parameter("Password", "XXX") });
        }

        [TestMethod]
        [TestCategory("StartSsisSetup")]
        [ExpectParameterBindingValidationException(MessagePattern = "ConnectionString")]
        public void TestInvokeWithEmptyConnectionStringThrows()
        {
            PsCmdletAssert.Invoke(typeof(StartSsisSetup), new[] { new Parameter("ConnectionString", string.Empty), new Parameter("SsisDatabase", "XXX"), new Parameter("Password", "XXX") });
        }

        [TestMethod]
        [TestCategory("StartSsisSetup")]
        [ExpectParameterBindingValidationException(MessagePattern = "ConnectionString")]
        public void TestInvokeWithNullConnectionStringThrows()
        {
            PsCmdletAssert.Invoke(typeof(StartSsisSetup), new[] { new Parameter("ConnectionString", null), new Parameter("SsisDatabase", "XXX"), new Parameter("Password", "XXX") });
        }

        [TestMethod]
        [TestCategory("StartSsisSetup")]
        [ExpectParameterBindingException(MessagePattern = "SsisDatabase")]
        public void TestInvokeWithMissingSsisDatabaseThrows()
        {
            PsCmdletAssert.Invoke(typeof(StartSsisSetup), new[] { new Parameter("ConnectionString", "123"), new Parameter("Password", "XXX") });
        }

        [TestMethod]
        [TestCategory("StartSsisSetup")]
        [ExpectParameterBindingValidationException(MessagePattern = "SsisDatabase")]
        public void TestInvokeWithEmptySsisDatabaseThrows()
        {
            PsCmdletAssert.Invoke(typeof(StartSsisSetup), new[] { new Parameter("ConnectionString", "123"), new Parameter("SsisDatabase", ""), new Parameter("Password", "XXX") });
        }

        [TestMethod]
        [TestCategory("StartSsisSetup")]
        [ExpectParameterBindingValidationException(MessagePattern = "SsisDatabase")]
        public void TestInvokeWithNullSsisDatabaseThrows()
        {
            PsCmdletAssert.Invoke(typeof(StartSsisSetup), new[] { new Parameter("ConnectionString", "123"), new Parameter("SsisDatabase", null), new Parameter("Password", "XXX") });
        }

        [TestMethod]
        [TestCategory("StartSsisSetup")]
        [ExpectParameterBindingException(MessagePattern = "Password")]
        public void TestInvokeWithMissingPasswordThrows()
        {
            PsCmdletAssert.Invoke(typeof(StartSsisSetup), new[] { new Parameter("ConnectionString", "123"), new Parameter("SsisDatabase", "xxx") });
        }

        [TestMethod]
        [TestCategory("StartSsisSetup")]
        [ExpectParameterBindingValidationException(MessagePattern = "Password")]
        public void TestInvokeWithEmptyPasswordThrows()
        {
            PsCmdletAssert.Invoke(typeof(StartSsisSetup), new[] { new Parameter("ConnectionString", "123"), new Parameter("SsisDatabase", "xxx"), new Parameter("Password", "") });
        }

        [TestMethod]
        [TestCategory("StartSsisSetup")]
        [ExpectParameterBindingValidationException(MessagePattern = "Password")]
        public void TestInvokeWithNullPasswordThrows()
        {
            PsCmdletAssert.Invoke(typeof(StartSsisSetup), new[] { new Parameter("ConnectionString", "123"), new Parameter("SsisDatabase", "xxx"), new Parameter("Password", null) });
        }

        [TestMethod]
        [TestCategory("StartSsisSetup")]
        [Ignore] //only used for debug purposes.
        public void TestUpdatesDatabase()
        {
            PsCmdletAssert.Invoke(typeof(StartSsisSetup), new[] { new Parameter("ConnectionString", "Data Source='.';Initial Catalog='master';Integrated Security=SSPI;MultipleActiveResultSets=True"), new Parameter("SsisDatabase", "SSISDB"), new Parameter("Password", "Br1tneyX") });
        }
    }
}