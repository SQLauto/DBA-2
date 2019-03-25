using System;
using System.Management.Automation;
using Deployment.Common.Helpers;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Tfl.Module.Testing;
using TFL.PowerShell.Logging.Commands;

namespace TFL.PowerShell.Logging.Tests
{
    [TestClass]
    public class WriteHeaderTests
    {
        [TestMethod]
        public void TestWritesHeader()
        {
            var parameters = new[]
            {
                new Parameter("Path", "Log.log")            };

            var result = PsCmdletAssert.Invoke(typeof(RegisterLogFileCommand), parameters );

            Assert.IsTrue(result != null);
            Assert.IsTrue(result.Count == 1);

            var log = result[0];

            result = PsCmdletAssert.Invoke(typeof(WriteHost2Command), new[]{ new Parameter("Object", "Hello world") });

            parameters = new[]
            {
                new Parameter("Title", "Test String"),
                new Parameter("AsSubHeader", true)
            };

            result = PsCmdletAssert.Invoke(typeof(WriteHeaderCommand), parameters);

            Assert.IsTrue(result != null);
        }
    }
}
