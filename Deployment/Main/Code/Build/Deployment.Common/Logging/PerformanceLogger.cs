using System;
using System.Diagnostics;

namespace Deployment.Common.Logging
{
    public class PerformanceLogger : IDeploymentLogger
    {
        private bool _disposed;
        private readonly IDeploymentLogger _logger;

        public PerformanceLogger(IDeploymentLogger logger = null)
        {
            _logger = logger;
            TimeTaken = "0.00";
            _stopwatch = new Stopwatch();
            _stopwatch.Start();

        }

        public void Restart()
        {
            _stopwatch?.Restart();
        }

        public void Pause()
        {
            _stopwatch?.Stop();
        }

        public void Resume()
        {
            _stopwatch?.Start();
        }

        private readonly Stopwatch _stopwatch;
        public string TestName { get; set; }
        public bool TestResult { get; set; }
        public string TimeTaken { get; private set; }

        public void Dispose()
        {
            if (_disposed)
                return;

            _disposed = true;

            if (_stopwatch == null)
                return;

            _stopwatch?.Stop();
            TimeTaken = GetElapsedTime();
        }

        void IDeploymentLogger.WriteHeader(string title, bool asSubHeader)
        {
            throw new NotSupportedException();
        }

        public void WriteLine(string message)
        {
            _logger?.WriteLine($"{message} (Elapsed time: {GetElapsedTime()}).");
        }

        public void WriteSummary(string message, LogResult result = LogResult.None)
        {
            _logger?.WriteSummary($"{message} (Elapsed time: {GetElapsedTime()}).", result);
        }

        public void WriteWarn(string message)
        {
            _logger?.WriteWarn($"{message} (Elapsed time: {GetElapsedTime()}).");
        }

        public void WriteError(string message)
        {
            _logger?.WriteError($"{message} (Elapsed time: {GetElapsedTime()}).");
        }

        void IDeploymentLogger.WriteError(Exception exception)
        {
            throw new NotSupportedException();
        }

        private string GetElapsedTime()
        {
            return _stopwatch?.Elapsed.TotalSeconds.ToString("0.00 seconds") ?? "None";
        }
    }
}