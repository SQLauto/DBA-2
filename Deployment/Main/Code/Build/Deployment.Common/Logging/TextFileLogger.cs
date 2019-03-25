using System;
using System.IO;
using System.Text;

namespace Deployment.Common.Logging
{
    public class TextFileLogger : IDeploymentLogger
    {
        private readonly TextFileLogger _summaryLogger;

        private const string DatetimeFormat = "dd/MM/yyyy H:mm:ss";
        private readonly string _logFile;
        private readonly StreamWriter _logWriter; // Local StreamWriter

        public TextFileLogger()
        {

        }

        public TextFileLogger(string logPath, string logFilename, TextFileLogger summaryLogger = null, StringBuilder testContextWriter = null)
        {
            _summaryLogger = summaryLogger;
            var path = logPath ?? AppDomain.CurrentDomain.BaseDirectory;

            _logFile = Path.Combine(path, logFilename);
            _logWriter = new StreamWriter(_logFile);
        }

        public string TimeNow = string.Format(DateTime.Now.ToString(DatetimeFormat));

        public void WriteHeader(string title, bool asSubHeader = false)
        {
            try
            {
                var message = asSubHeader
                ? string.Format(Strings.LogSubHeader, title, DateTime.Now.ToString("R"))
                : string.Format(Strings.LogHeader, DateTime.Now.ToString("R"), Environment.UserName,
                    Environment.UserDomainName, Environment.MachineName, Environment.OSVersion, title);

                WriteDateLine(message, false);

                _summaryLogger?.WriteDateLine(message, false);
            }
            // ReSharper disable once EmptyGeneralCatchClause
            catch (Exception)
            {

            }
        }

        public void WriteSummary(string message, LogResult result = LogResult.None)
        {
            try
            {
                var prefix = string.Empty;

                switch (result)
                {
                    case LogResult.Fail:
                        prefix = "Failure: ";
                        break;
                    case LogResult.Success:
                        prefix = "Success: ";
                        break;
                }

                message = prefix + message;

                WriteLine(message);
                _summaryLogger?.WriteDateLine(message, false);
            }
            // ReSharper disable once EmptyGeneralCatchClause
            catch (Exception)
            {

            }
        }

        public void WriteLine(string message)
        {
            WriteDateLine(message);
        }

        public void WriteDateLine(string message, bool datePrefix = true)
        {
            try
            {
                if (!File.Exists(_logFile)) return;

                var prefix = datePrefix ? DateTime.Now.ToString(DatetimeFormat) + " :  " : string.Empty;

                _logWriter?.WriteLine(prefix + message);
                _logWriter?.Flush();
            }
            // ReSharper disable once EmptyGeneralCatchClause
            catch (Exception)
            {
                throw;
            }
        }

        public void WriteWarn(string message)
        {
            try
            {
                if (!File.Exists(_logFile)) return;
                WriteDateLine(DateTime.Now.ToString(DatetimeFormat) + " :  WARN - " + message, false);
            }
            // ReSharper disable once EmptyGeneralCatchClause
            catch (Exception)
            {
                throw;
            }
        }

        public void WriteError(string message)
        {
            try
            {
                if (!File.Exists(_logFile)) return;

                WriteDateLine(DateTime.Now.ToString(DatetimeFormat) + " :  ERROR - " + message, false);
            }
            // ReSharper disable once EmptyGeneralCatchClause
            catch (Exception)
            {
                throw;
            }
        }

        public void WriteError(Exception exception)
        {
            //_logWriter?.WriteLine(DateTime.Now.ToString(DatetimeFormat) + " :  " + message);
        }

        public void Dispose()
        {
            _summaryLogger?.Dispose();
            _logWriter?.Close();
            _logWriter?.Dispose();
        }
    }
}