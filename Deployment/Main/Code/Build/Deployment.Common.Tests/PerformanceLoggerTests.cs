using System;
using System.Threading;
using Deployment.Common.Logging;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Deployment.Common.Tests
{
    [TestClass]
    public class PerformanceLoggerTests
    {
        public TestContext TestContext { get; set; }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        public void TestsLoggerWithNullInternalLogger()
        {
            //arrange
            var perfLogger = new PerformanceLogger();

            //act
            perfLogger.WriteLine("No ouput shown");
            Thread.Sleep(1000);
            perfLogger.WriteLine("No ouput shown");
            perfLogger.Dispose();

            //assert
            Assert.IsFalse(perfLogger.TimeTaken.Equals("None"));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        public void TestsLoggerWithInternalLogger()
        {
            //arrange
            var logger = new TestContextLogger(TestContext);
            var perfLogger = new PerformanceLogger(logger);

            //act
            perfLogger.WriteLine("Output to writeline");
            Thread.Sleep(1000);
            perfLogger.WriteWarn("Output to warning");
            perfLogger.Dispose();

            //assert
            Assert.IsFalse(perfLogger.TimeTaken.Equals("None"));
            Assert.IsTrue(logger.Messages.Count == 2);
            Assert.IsTrue(logger.Messages[0].Contains("seconds"));
            Assert.IsTrue(logger.Messages[1].Contains("WARN:"));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        public void TestsLoggerWithInternalLoggerPauses()
        {
            //arrange
            var logger = new TestContextLogger(TestContext);
            var perfLogger = new PerformanceLogger(logger);

            //act
            perfLogger.WriteLine("Output to writeline");
            Thread.Sleep(1000);
            perfLogger.WriteWarn("Output to warning");
            Thread.Sleep(1000);
            perfLogger.Pause();

            var initial = perfLogger.TimeTaken;

            Thread.Sleep(1000);

            var current = perfLogger.TimeTaken;

            perfLogger.Dispose();

            //assert
            Assert.IsTrue(initial.Equals(current, StringComparison.InvariantCultureIgnoreCase));
        }
    }
}