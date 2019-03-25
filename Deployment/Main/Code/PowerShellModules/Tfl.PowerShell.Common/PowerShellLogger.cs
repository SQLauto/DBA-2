using System;
using System.Management.Automation;
using System.Text;
using Deployment.Common.Logging;

namespace Tfl.PowerShell.Common
{
    public class PowerShellLogger : IDeploymentLogger
    {
        private readonly Action<string> _writeAction;
        private readonly Action<string> _warnAction;
        private readonly Action<Exception, object, ErrorCategory, bool> _errorAction;
        public PowerShellLogger(Action<string> writeAction, Action<string> warnAction, Action<Exception, object, ErrorCategory, bool> errorAction)
        {
            _writeAction = writeAction;
            _warnAction = warnAction;
            _errorAction = errorAction;
        }

        public void Dispose()
        {

        }

        public void WriteHeader(string title, bool asSubHeader = false)
        {

        }

        public void WriteLine(string message)
        {
            _writeAction?.Invoke(message);
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

            _writeAction?.Invoke(prefix + message);
        }

        public void WriteWarn(string message)
        {
            _warnAction?.Invoke(message);
        }

        public void WriteError(string message)
        {
            var exception = new ApplicationException(message);
            WriteError(exception);
        }

        public void WriteError(Exception exception)
        {
            var builder = new StringBuilder();
            var parent = exception;

            var aggregateException = exception as AggregateException;

            if (aggregateException != null)
            {
                foreach (var ex in aggregateException.Flatten().InnerExceptions)
                {
                    builder.Append(Environment.NewLine).Append("\tException :" + ex.GetType().FullName)
                        .Append(Environment.NewLine).Append("\tSource :" + ex.Source)
                        .Append(Environment.NewLine).Append("\tStackTrace :" + ex.StackTrace);
                }
            }
            else
            {
                while (exception != null)
                {
                    builder.Append(Environment.NewLine).Append("\tException: " + exception.GetType().FullName)
                        .Append(Environment.NewLine).Append("\tSource: " + exception.Source)
                        .Append(Environment.NewLine).Append("\tStackTrace: " + exception.StackTrace);

                    exception = exception.InnerException;

                    if (exception != null)
                    {
                        builder.Append(Environment.NewLine).Append("\t--- INNER EXCEPTION ---");
                    }
                }
            }

            _errorAction?.Invoke(parent, this, ErrorCategory.NotSpecified, false);
            _writeAction?.Invoke(builder.ToString());
        }
    }
}