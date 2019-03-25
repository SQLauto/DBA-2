using System;
using Deployment.Common;
using Deployment.Common.Logging;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Deployment.Domain.Operations.Tests
{
    public class TestContextLogger : IDeploymentLogger
    {
        private readonly TestContext _testContext;

        public TestContextLogger(TestContext testContext)
        {
            _testContext = testContext;
        }
        public void Dispose()
        {
        }

        public void WriteHeader(string title, bool asSubHeader = false)
        {

        }

        public void WriteLine(string message)
        {
            _testContext.WriteLine(message);
        }

        public void WriteSummary(string message, LogResult result = LogResult.None)
        {
            var prefix = string.Empty;

            if (result == LogResult.Fail)
                prefix = "Failure: ";

            if (result == LogResult.Success)
                prefix = "Success: ";

            if (result == LogResult.Error)
                prefix = "Error: ";

            WriteLine(prefix + message);
        }

        public void WriteWarn(string message)
        {
            _testContext.WriteLine("WARN: " + message);
        }

        public void WriteError(string message)
        {
            _testContext.WriteLine("ERROR: " + message);
        }

        public void WriteError(Exception exception)
        {
            _testContext.WriteLine("ERROR: " + exception.BuildExceptionMessage());
        }
    }
}
