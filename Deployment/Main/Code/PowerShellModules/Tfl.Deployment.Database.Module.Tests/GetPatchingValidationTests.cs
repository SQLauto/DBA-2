using System;
using Deployment.Common.Helpers;
using Deployment.Database;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Tfl.Deployment.Database.Commands;
using Tfl.Module.Testing;

namespace Tfl.Deployment.Database.Module.Tests
{
    [TestClass]
    public class GetPatchingValidationTests
    {
        [TestMethod]
        [TestCategory("PatchingValidation")]
        [ExpectParameterBindingException(MessagePattern = "ConnectionString")]
        public void TestInvokeWithMissingConnectionStringThrows()
        {
            PsCmdletAssert.Invoke(typeof(GetPatchingValidation), new[] { new Parameter("Type", "Post") });
        }

        [TestMethod]
        [TestCategory("PatchingValidation")]
        [ExpectParameterBindingValidationException(MessagePattern = "ConnectionString")]
        public void TestInvokeWithEmptyConnectionStringThrows()
        {
            PsCmdletAssert.Invoke(typeof(GetPatchingValidation), new[] { new Parameter("ConnectionString", string.Empty), new Parameter("Type", "Post") });
        }

        [TestMethod]
        [TestCategory("PatchingValidation")]
        [ExpectParameterBindingValidationException(MessagePattern = "ConnectionString")]
        public void TestInvokeWithNullConnectionStringThrows()
        {
            PsCmdletAssert.Invoke(typeof(GetPatchingValidation), new[] { new Parameter("ConnectionString", null), new Parameter("Type", "Post") });
        }

        [TestMethod]
        [TestCategory("PatchingValidation")]
        [ExpectParameterBindingException(MessagePattern = "Type")]
        public void TestInvokeWithMissingTypeThrows()
        {
            PsCmdletAssert.Invoke(typeof(GetPatchingValidation), new[] { new Parameter("ConnectionString", "Value") });
        }

        [TestMethod]
        [TestCategory("PatchingValidation")]
        [ExpectParameterBindingValidationException(MessagePattern = "Type")]
        public void TestInvokeWithEmptyTypeThrows()
        {
            PsCmdletAssert.Invoke(typeof(GetPatchingValidation), new[] { new Parameter("ConnectionString", "Value"), new Parameter("Type", string.Empty) });
        }

        [TestMethod]
        [TestCategory("PatchingValidation")]
        [ExpectParameterBindingValidationException(MessagePattern = "Type")]
        public void TestInvokeWithNullTypeThrows()
        {
            PsCmdletAssert.Invoke(typeof(GetPatchingValidation), new[] { new Parameter("ConnectionString", "Value"), new Parameter("Type", null) });
        }

        [TestMethod]
        [TestCategory("PatchingValidation")]
        [ExpectParameterBindingValidationException(MessagePattern = "Type")]
        public void TestInvokeWitInvalidTypeThrows()
        {
            PsCmdletAssert.Invoke(typeof(GetPatchingValidation), new[] { new Parameter("ConnectionString", "Value"), new Parameter("Type", "NotValid") });
        }

        [TestMethod]
        [Ignore]
        public void TestInvokesPreSuccessfully() //Note that to run this test you must amend to use a valid connection string. set to ignore otherwise
        {
            var result = PsCmdletAssert.Invoke(typeof(GetPatchingValidation), new[] { new Parameter("ConnectionString", "Data Source=(local);Initial Catalog=SingleSignOn;Integrated Security=true"), new Parameter("Type", "Pre") });
            Assert.AreEqual(result.Count, 1, "Passed count from call to Get-PatchingValidation should be 1.");
        }

        [TestMethod]
        [Ignore]
        public void TestInvokesPostSuccessfully() //Note that to run this test you must amend to use a valid connection string. set to ignore otherwise
        {
            var result = PsCmdletAssert.Invoke(typeof(GetPatchingValidation), new[] { new Parameter("ConnectionString", "Data Source=(local);Initial Catalog=SingleSignOn;Integrated Security=true"), new Parameter("Type", "Post") });
            Assert.AreEqual(result.Count, 1, "Passed count from call to Get-PatchingValidation should be 1.");
        }
    }
}
