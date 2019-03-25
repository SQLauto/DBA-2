using Deployment.Common.Helpers;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Tfl.Deployment.Database.Commands;
using Tfl.Module.Testing;

namespace Tfl.Deployment.Database.Module.Tests
{
    [TestClass]
    public class InvokeExecuteScalarTests
    {
        [TestMethod]
        [TestCategory("ExecuteScalar")]
        [ExpectParameterBindingException(MessagePattern = "ConnectionString")]
        public void TestInvokeWithMissingConnectionStringThrows()
        {
            PsCmdletAssert.Invoke(typeof(InvokeExecuteScalar), new[] { new Parameter("CommandText", "Test") });
        }

        [TestMethod]
        [TestCategory("ExecuteScalar")]
        [ExpectParameterBindingValidationException(MessagePattern = "ConnectionString")]
        public void TestInvokeWithEmptyConnectionStringThrows()
        {
            PsCmdletAssert.Invoke(typeof(InvokeExecuteScalar), new[] { new Parameter("ConnectionString", string.Empty), new Parameter("CommandText", "Test") });
        }

        [TestMethod]
        [TestCategory("ExecuteScalar")]
        [ExpectParameterBindingValidationException(MessagePattern = "ConnectionString")]
        public void TestInvokeWithNullConnectionStringThrows()
        {
            PsCmdletAssert.Invoke(typeof(InvokeExecuteScalar), new[] { new Parameter("ConnectionString", null), new Parameter("CommandText", "Test") });
        }

        [TestMethod]
        [TestCategory("ExecuteScalar")]
        [ExpectParameterBindingException(MessagePattern = "CommandText")]
        public void TestInvokeWithMissingCommandTextThrows()
        {
            PsCmdletAssert.Invoke(typeof(InvokeExecuteScalar), new[] { new Parameter("ConnectionString", "ConnString") });
        }

        [TestMethod]
        [TestCategory("ExecuteScalar")]
        [ExpectParameterBindingValidationException(MessagePattern = "CommandText")]
        public void TestInvokeWithEmptyCommandTextThrows()
        {
            PsCmdletAssert.Invoke(typeof(InvokeExecuteScalar), new[] { new Parameter("ConnectionString", "ConnString"), new Parameter("CommandText", "") });
        }

        [TestMethod]
        [TestCategory("ExecuteScalar")]
        [ExpectParameterBindingValidationException(MessagePattern = "CommandText")]
        public void TestInvokeWithNullCommandTextThrows()
        {
            PsCmdletAssert.Invoke(typeof(InvokeExecuteScalar), new[] { new Parameter("ConnectionString", "ConnString"), new Parameter("CommandText", null) });
        }

        [TestMethod]
        [TestCategory("ExecuteScalar")]
        public void TestInvokeSuccessful()
        {
            var result = PsCmdletAssert.Invoke(typeof(InvokeExecuteScalar), new[] { new Parameter("ConnectionString", "Data Source=(local);Initial Catalog=Master;Integrated Security=true"), new Parameter("CommandText", @"set nocount on; select case when exists(select 1 from sys.databases where name = 'SingleSignOn') then 1 else 0 end") });
            Assert.IsTrue(result.Count == 1);
            var value = result[0].BaseObject;
            Assert.IsInstanceOfType(value, typeof(int));
        }
    }
}