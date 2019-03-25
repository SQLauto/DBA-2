using Deployment.Common.Helpers;
using Deployment.Installation;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Tfl.Deployment.Commands;
using Tfl.Module.Testing;

namespace Tfl.Deployment.Module.Tests
{
    [TestClass]
    public class AssertExpectedProductCodeCommandTests
    {
        [TestMethod]
        [TestCategory("ExpectedProductCode")]
        [ExpectParameterBindingException(MessagePattern = "ProductCode")]
        public void TestInvokeWithNullProductCodeThrows()
        {
            PsCmdletAssert.Invoke(typeof(AssertExpectedProductCodeCommand), new[] {new Parameter("MsiKey", new MsiKey())});
        }

        [TestMethod]
        [TestCategory("ExpectedProductCode")]
        [ExpectParameterBindingValidationException(MessagePattern = "ProductCode")]
        public void TestInvokeWithEmptyProductCodeThrows()
        {
            PsCmdletAssert.Invoke(typeof(AssertExpectedProductCodeCommand), new[] { new Parameter("ProductCode", string.Empty),  new Parameter("MsiKey", new MsiKey()) });
        }

        [TestMethod]
        [TestCategory("ExpectedProductCode")]
        [ExpectParameterBindingException(MessagePattern = "MsiKey")]
        public void TestInvokeWithMissingMsiKeyThrows()
        {
            PsCmdletAssert.Invoke(typeof(AssertExpectedProductCodeCommand), new[] { new Parameter("ProductCode", "123") });
        }

        [TestMethod]
        [TestCategory("ExpectedProductCode")]
        [ExpectParameterBindingValidationException(MessagePattern = "MsiKey")]
        public void TestInvokeWithNullMsiKeyThrows()
        {
            PsCmdletAssert.Invoke(typeof(AssertExpectedProductCodeCommand), new[] { new Parameter("ProductCode", "123"), new Parameter("MsiKey",null) });
        }
    }
}