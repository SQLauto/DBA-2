using Deployment.Common.Helpers;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Tfl.Module.Testing;
using TFL.Deployment.VCloud.Commands;

namespace TFL.Deployment.VCloud.Tests
{
    [TestClass]
    public class GetVAppResourceIdCommandTests
    {
        public TestContext TestContext { get; set; }

        [TestMethod]
        [TestCategory("vCloud")]
        [ExpectParameterBindingException(MessagePattern = "RigName")]
        public void TestInvokeWithRigNameThrows()
        {
            PsCmdletAssert.Invoke(typeof(GetVAppResourceIdCommand), new[] { new Parameter("Url", "SomeValue") });
        }

        [TestMethod]
        [TestCategory("vCloud")]
        [ExpectParameterBindingValidationException(MessagePattern = "RigName")]
        public void TestInvokeWithNullRigNameThrows()
        {
            PsCmdletAssert.Invoke(typeof(GetVAppResourceIdCommand), new[] { new Parameter("RigName", null), new Parameter("Url", "SomeValue") });
        }

        [TestMethod]
        [TestCategory("vCloud")]
        [ExpectParameterBindingValidationException(MessagePattern = "RigName")]
        public void TestInvokeWithEmptyRigNameThrows()
        {
            PsCmdletAssert.Invoke(typeof(GetVAppResourceIdCommand), new[] { new Parameter("RigName", ""), new Parameter("Url", "SomeValue") });
        }

        [TestMethod]
        [TestCategory("vCloud")]
        public void TestReturnsVAppResourceId()
        {
            var encryptionHelper = new EncryptionHelper();
            var secureString = encryptionHelper.ConvertToSecureString("P0wer5hell");

            var parameters = new[]
            {
                new Parameter("Url", "https://vcloud.onelondon.tfl.local"),
                new Parameter("Organisation", "ce_organisation_td"),
                new Parameter("Username", "zSVCCEVcloudBuild"),
                new Parameter("Password", secureString)
            };

            var result = PsCmdletAssert.Invoke(typeof(ConnectVCloudCommand), parameters);

            var subscriber = (IHostSubscriber)result[0].BaseObject;

            result = PsCmdletAssert.Invoke(typeof(GetVAppResourceIdCommand), new[] { new Parameter("ComputerName", "TS-DB1") });
            Assert.IsTrue(result != null, "Call to invoke returned null");
            Assert.AreEqual(result.Count, 1, "Invoke result contains incorrect number of return items, expected 1");

            PsCmdletAssert.Invoke(typeof(DisconnectVCloudCommand), new[] { new Parameter("InputObject", subscriber) });
        }
    }
}