using System;

namespace TFL.PowerShell.Logging
{
    [Flags]
    public enum LogState : byte
    {
        None = 0,
        NoTimestamp = 1 << 0,
        NoConsole = 1 << 1,
        NoLog = 1 << 2,
        CacheLog = 1 << 3,
        All = NoTimestamp | NoConsole | NoLog | CacheLog
    }
}