using System;
using Deployment.Common.Helpers;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Tfl.Module.Testing;
using TFL.Utilities.Commands;

namespace TFL.Utilities.Module.Tests
{
    [TestClass]
    public class ProtectPasswordCommandTests
    {
        [TestMethod]
        [TestCategory("Encryption")]
        [ExpectParameterBindingException(MessagePattern = "EncryptionPassword")]
        public void TestInvokeWithMissingEncryptionPasswordThrows()
        {
            PsCmdletAssert.Invoke(typeof(ProtectPasswordCommand), new[] { new Parameter("Value", "SomeValue") });
        }

        [TestMethod]
        [TestCategory("Encryption")]
        [ExpectParameterBindingValidationException(MessagePattern = "EncryptionPassword")]
        public void TestInvokeWithNullEncryptionPasswordThrows()
        {
            PsCmdletAssert.Invoke(typeof(ProtectPasswordCommand), new[] { new Parameter("EncryptionPassword",null), new Parameter("Value", "SomeValue") });
        }

        [TestMethod]
        [TestCategory("Encryption")]
        public void TestReturnsEncryptedPasswordAsPlainText()
        {
            var encryptionHelper = new EncryptionHelper();

            var secureString = encryptionHelper.ConvertToSecureString("Olymp1c$2010");

            var result = PsCmdletAssert.Invoke(typeof(ProtectPasswordCommand), new[] { new Parameter("EncryptionPassword", secureString), new Parameter("Value", "SomeValue") });

            Assert.IsTrue(result.Count == 1);

            var output = (string)result[0].BaseObject;

            Assert.IsTrue(output.Equals("UpjGOvF+gZlV8o7Ln49etQ==", StringComparison.InvariantCulture));
        }
    }
}