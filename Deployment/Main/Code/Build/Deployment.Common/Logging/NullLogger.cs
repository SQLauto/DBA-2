using System;
using System.Management.Instrumentation;

namespace Deployment.Common.Logging
{
    public class NullLogger : IDeploymentLogger
    {
        public void Dispose()
        {

        }

        public void WriteHeader(string title, bool asSubHeader = false)
        {

        }

        public void WriteLine(string message)
        {

        }

        public void WriteSummary(string message, LogResult result = LogResult.None)
        {

        }

        public void WriteWarn(string message)
        {

        }

        public void WriteError(string message)
        {

        }

        public void WriteError(Exception exception)
        {

        }

        public static NullLogger Instance => new NullLogger();
    }
}