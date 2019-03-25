using System;
using System.Collections.Generic;

namespace Deployment.Common.Logging
{
    public class ConsoleLogger : IDeploymentLogger
    {
        private readonly List<string> _errors;

        public ConsoleLogger()
        {
            _errors = new List<string>();
        }

        public void WriteSummary(string message, LogResult result = LogResult.None)
        {
            var prefix = string.Empty;

            if (result == LogResult.Fail)
                prefix = "Failure: ";

            if (result == LogResult.Success)
                prefix = "Success: ";

            WriteLine(prefix + message);
        }

        public void WriteHeader(string title, bool asSubHeader = false)
        {
        }

        public void WriteLine(string message)
        {
            WriteToConsole(ConsoleColor.Green, message);
        }

        public void WriteWarn(string message)
        {
            WriteToConsole(ConsoleColor.Yellow, message);
        }

        public void WriteError(string message)
        {
            WriteToConsole(ConsoleColor.Red, message);
        }

        public void WriteError(Exception exception)
        {
            var message = exception.BuildExceptionMessage();
            WriteToConsole(ConsoleColor.Red, message);
        }

        public void Dispose()
        {
        }

        private void WriteToConsole(string format, params object[] formatArguments)
        {
            Console.WriteLine(format, formatArguments);

            Console.Out.Flush();
        }

        private void WriteToConsole(ConsoleColor foregroundColor, string format, params object[] formatArguments)
        {
            var originalColor = Console.ForegroundColor;
            Console.ForegroundColor = foregroundColor;

            Console.WriteLine(format, formatArguments);

            Console.Out.Flush();

            Console.ForegroundColor = originalColor;
        }
    }
}