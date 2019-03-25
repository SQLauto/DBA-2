namespace TFL.PowerShell.Logging
{
    internal static class Constants
    {
        public const string Header =
            @"#########################################################################################
Title: {5}
Start Date: {0}
UserName: {1}
UserDomain: {2}
ComputerName: {3}
Windows version: {4}
#########################################################################################
";

        public const string SubHeader =
            @"--------------------------------------------------------------------------------------------------------
{0} at {1} {2}
--------------------------------------------------------------------------------------------------------";

        public const string NoConsole = "NOCONSOLE";
        public const string NoLog = "NOLOG";
        public const string NoTimestamp = "NOSTAMP";
        public const string PsHost = "PSHOST";
        public const string CacheLog = "CACHELOG";
    }
}