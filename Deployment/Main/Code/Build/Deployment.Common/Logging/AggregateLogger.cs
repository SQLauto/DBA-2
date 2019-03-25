using System;
using System.Collections.Generic;

namespace Deployment.Common.Logging
{
    public class AggregateLogger : IDeploymentLogger
    {
        private readonly IList<IDeploymentLogger> _loggers;

        public AggregateLogger()
        {
            _loggers = new List<IDeploymentLogger>();
        }

        public AggregateLogger(IList<IDeploymentLogger> loggers) : this()
        {
            _loggers.AddRange(loggers);
        }

        public void AddLogger(IDeploymentLogger logger)
        {
            _loggers.Add(logger);
        }

        public void WriteHeader(string title, bool asSubHeader = false)
        {
            foreach (var logger in _loggers)
            {
                logger.WriteHeader(title, asSubHeader);
            }
        }

        public void WriteLine(string message)
        {
            foreach (var logger in _loggers)
            {
                logger.WriteLine(message);
            }
        }

        public void WriteSummary(string message, LogResult result = LogResult.None)
        {
            foreach (var logger in _loggers)
            {
                logger.WriteSummary(message, result);
            }
        }

        public void WriteWarn(string message)
        {
            foreach (var logger in _loggers)
            {
                logger.WriteWarn(message);
            }
        }

        public void WriteError(string message)
        {
            foreach (var logger in _loggers)
            {
                logger.WriteError(message);
            }
        }

        public void WriteError(Exception exception)
        {
            foreach (var logger in _loggers)
            {
                logger.WriteError(exception);
            }
        }

        public void Dispose()
        {
            foreach (var logger in _loggers)
            {
                logger.Dispose();
            }
        }
    }
}