using System;

namespace Deployment.Tool
{
    internal class Program
    {
        private const int ErrorUnknown = 0xA0;
        private const int ErrorTaskFailed = 0x216;
        private const int ErrorInvalidCommandLine = 0x667;

        /// <summary>
        ///     The main entry point for the application.
        /// </summary>
        [STAThread]
        private static int Main(string[] args)
        {
            if (args.Length == 1)
            {
                Environment.ExitCode = ErrorInvalidCommandLine;

                ConsoleHarness.WriteError("Invalid Arguments");

                return Environment.ExitCode;
            }

            using (var harness = new ConsoleHarness())
            {
                if (harness.Initialise(args) != ConsoleResult.Success)
                {
                    Environment.ExitCode = ErrorInvalidCommandLine;
                    return Environment.ExitCode;
                }

                try
                {
                    var result = harness.Run();

                    if (result == ConsoleResult.Fail)
                        Environment.ExitCode = ErrorTaskFailed;
                }
                catch
                {
                    Environment.ExitCode = ErrorUnknown;
                }
            }

            return Environment.ExitCode;
        }
    }
}