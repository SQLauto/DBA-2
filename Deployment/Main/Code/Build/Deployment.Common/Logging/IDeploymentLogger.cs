using System;

namespace Deployment.Common.Logging
{
    public enum LogResult
    {
        None = 0,
        Success,
        Fail,
        Error
    }


    public interface IDeploymentLogger : IDisposable
    {
        void WriteHeader(string title, bool asSubHeader = false);
        void WriteLine(string message);
        void WriteSummary(string message, LogResult result = LogResult.None);
        void WriteWarn(string message);
        void WriteError(string message);
        void WriteError(Exception exception);
    }
}