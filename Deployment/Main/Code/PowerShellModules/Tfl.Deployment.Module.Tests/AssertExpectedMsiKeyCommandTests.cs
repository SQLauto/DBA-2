using System;
using Deployment.Common.Helpers;
using Deployment.Installation;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Tfl.Deployment.Commands;
using Tfl.Module.Testing;

namespace Tfl.Deployment.Module.Tests
{
    [TestClass]
    public class AssertExpectedMsiKeyCommandTests
    {
        [TestMethod]
        [TestCategory("ExpectedMsiKey")]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [ExpectParameterBindingException(MessagePattern = "MsiKey")]
        public void TestInvokeWithMissingMsiKeyThrows()
        {
            PsCmdletAssert.Invoke(typeof(AssertExpectedMsiKeyCommand), new[] { new Parameter("UpgradeCode", "123"), new Parameter("ProductCode","123") });
        }

        [TestMethod]
        [TestCategory("ExpectedMsiKey")]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [ExpectParameterBindingValidationException(MessagePattern = "MsiKey")]
        public void TestInvokeWithNullMsiKeyThrows()
        {
            PsCmdletAssert.Invoke(typeof(AssertExpectedMsiKeyCommand), new[] { new Parameter("MsiKey", null), new Parameter("UpgradeCode", "123"), new Parameter("ProductCode", "123") });
        }

        [TestMethod]
        [TestCategory("ExpectedMsiKey")]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [ExpectCmdletInvocationException(MessagePattern = "This is invalid")]
        public void TestInvokeWithNulProductCodeUpgradeCodeThrows()
        {
            PsCmdletAssert.Invoke(typeof(AssertExpectedMsiKeyCommand), new[] { new Parameter("MsiKey", new MsiKey()), new Parameter("UpgradeCode", null), new Parameter("ProductCode", null) });
        }

        [TestMethod]
        [TestCategory("ExpectedMsiKey")]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [ExpectCmdletInvocationException(MessagePattern = "This is invalid")]
        public void TestInvokeWithEqualProductCodeUpgradeCodeThrows()
        {
            PsCmdletAssert.Invoke(typeof(AssertExpectedMsiKeyCommand), new[] { new Parameter("MsiKey", new MsiKey()), new Parameter("UpgradeCode", "123"), new Parameter("ProductCode", "123") });
        }

        [TestMethod]
        [TestCategory("ExpectedMsiKey")]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [ExpectCmdletInvocationException(MessagePattern = "MSI Key")]
        public void TestInvokeWithInvalidMsiKeyThrows()
        {
            var guid = Guid.NewGuid();
            PsCmdletAssert.Invoke(typeof(AssertExpectedMsiKeyCommand), new[] { new Parameter("MsiKey", new MsiKey(guid, guid, default(Version))), new Parameter("UpgradeCode", "123"), new Parameter("ProductCode", null) });
        }

        [TestMethod]
        [TestCategory("ExpectedMsiKey")]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [ExpectCmdletInvocationException(MessagePattern = "valid Version")]
        public void TestInvokeWithInvalidMsiKeyVersionThrows()
        {
            PsCmdletAssert.Invoke(typeof(AssertExpectedMsiKeyCommand), new[] { new Parameter("MsiKey", new MsiKey(Guid.NewGuid(), Guid.NewGuid(), default(Version))), new Parameter("UpgradeCode", "123"), new Parameter("ProductCode", null) });
        }

        [TestMethod]
        [TestCategory("ExpectedMsiKey")]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [ExpectCmdletInvocationException(MessagePattern = "expected product code")]
        public void TestInvokeWithInvalidMsiKeyProductCodeThrows()
        {
            PsCmdletAssert.Invoke(typeof(AssertExpectedMsiKeyCommand), new[] { new Parameter("MsiKey", new MsiKey(Guid.NewGuid(), Guid.Empty, new Version(1,1))), new Parameter("UpgradeCode", null), new Parameter("ProductCode", Guid.NewGuid().ToString()) });
        }

        [TestMethod]
        [TestCategory("ExpectedMsiKey")]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [ExpectCmdletInvocationException(MessagePattern = "must not be empty")]
        public void TestInvokeWithEmptyGuidProductCodeThrows()
        {
            PsCmdletAssert.Invoke(typeof(AssertExpectedMsiKeyCommand), new[] { new Parameter("MsiKey", new MsiKey(Guid.NewGuid(), Guid.Empty, new Version(1, 1))), new Parameter("UpgradeCode", null), new Parameter("ProductCode", Guid.Empty.ToString()) });
        }

        [TestMethod]
        [TestCategory("ExpectedMsiKey")]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [ExpectCmdletInvocationException(MessagePattern = "expected upgrade code")]
        public void TestInvokeWithInvalidMsiKeyUpgadeCodeThrows()
        {
            PsCmdletAssert.Invoke(typeof(AssertExpectedMsiKeyCommand), new[] { new Parameter("MsiKey", new MsiKey(Guid.Empty, Guid.NewGuid(), new Version(1, 1))), new Parameter("UpgradeCode", Guid.NewGuid().ToString()), new Parameter("ProductCode", null) });
        }
    }
}