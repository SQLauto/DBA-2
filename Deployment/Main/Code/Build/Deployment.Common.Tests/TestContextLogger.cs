using System;
using System.Collections.Generic;
using Deployment.Common.Logging;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Deployment.Common.Tests
{
    public class TestContextLogger : IDeploymentLogger
    {
        private readonly TestContext _testContext;

        public TestContextLogger(TestContext testContext)
        {
            _testContext = testContext;
            Messages = new List<string>();
        }
        public void Dispose()
        {
        }

        public IList<string> Messages { get; }

        public void WriteHeader(string title, bool asSubHeader = false)
        {

        }

        public void WriteLine(string message)
        {
            _testContext.WriteLine(message);
            Messages.Add(message);
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

            Messages.Add(prefix + message);
        }

        public void WriteWarn(string message)
        {
            _testContext.WriteLine("WARN: " + message);
            Messages.Add("WARN: " + message);
        }

        public void WriteError(string message)
        {
            _testContext.WriteLine("ERROR: " + message);
            Messages.Add("ERROR: " + message);
        }

        public void WriteError(Exception exception)
        {
            _testContext.WriteLine("ERROR: " + exception.BuildExceptionMessage());
        }
    }
}
