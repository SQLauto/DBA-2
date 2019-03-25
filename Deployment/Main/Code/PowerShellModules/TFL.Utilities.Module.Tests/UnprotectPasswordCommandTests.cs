using System;
using Deployment.Common.Helpers;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Tfl.Module.Testing;
using TFL.Utilities.Commands;

namespace TFL.Utilities.Module.Tests
{
    [TestClass]
    public class UnprotectPasswordCommandTests
    {
        [TestMethod]
        [TestCategory("Encryption")]
        [ExpectParameterBindingException(MessagePattern = "DecryptionPassword")]
        public void TestInvokeWithMissingEncryptionPasswordThrows()
        {
            PsCmdletAssert.Invoke(typeof(UnprotectPasswordCommand), new[] { new Parameter("Value", "SomeValue") });
        }
        [TestMethod]
        [TestCategory("Encryption")]
        [ExpectParameterBindingValidationException(MessagePattern = "DecryptionPassword")]
        public void TestInvokeWithNullEncryptionPasswordThrows()
        {
            PsCmdletAssert.Invoke(typeof(UnprotectPasswordCommand), new[] { new Parameter("DecryptionPassword", null), new Parameter("Value", "SomeValue") });
        }
        [TestMethod]
        [TestCategory("Encryption")]
        public void TestReturnsUnencryptedPasswordAsPlainText()
        {
            var encryptionHelper = new EncryptionHelper();
            var secureString = encryptionHelper.ConvertToSecureString("Olymp1c$2010");
            var result = PsCmdletAssert.Invoke(typeof(UnprotectPasswordCommand), new[] { new Parameter("DecryptionPassword", secureString), new Parameter("Value", "UpjGOvF+gZlV8o7Ln49etQ==") });
            Assert.IsTrue(result.Count == 1);
            var output = (string)result[0].BaseObject;
            Assert.IsTrue(output.Equals("SomeValue", StringComparison.InvariantCulture));
        }
    }
}