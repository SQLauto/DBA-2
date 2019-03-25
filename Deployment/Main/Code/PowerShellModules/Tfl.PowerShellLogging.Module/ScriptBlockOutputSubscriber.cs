// ReSharper disable MemberCanBePrivate.Global
// ReSharper disable UnusedMember.Global

using System.Management.Automation;

namespace TFL.PowerShell.Logging
{
    public class ScriptBlockOutputSubscriber : HostIoSubscriberBase
    {
        public ScriptBlockOutputSubscriber(ScriptBlock onWriteOutput,
                                           ScriptBlock onWriteDebug,
                                           ScriptBlock onWriteVerbose,
                                           ScriptBlock onWriteError,
                                           ScriptBlock onWriteWarning)
        {
            OnWriteOutput = onWriteOutput;
            OnWriteDebug = onWriteDebug;
            OnWriteVerbose = onWriteVerbose;
            OnWriteError = onWriteError;
            OnWriteWarning = onWriteWarning;
        }

        public ScriptBlockOutputSubscriber() : this(null, null, null, null, null) {}

        public ScriptBlock OnWriteDebug { get; set; }
        public ScriptBlock OnWriteOutput { get; set; }
        public ScriptBlock OnWriteError { get; set; }
        public ScriptBlock OnWriteVerbose { get; set; }
        public ScriptBlock OnWriteWarning { get; set; }

        public override void WriteDebugLine(string message)
        {
            if (OnWriteDebug != null)
            {
                OnWriteDebug.Invoke(message);
            }
        }

        public override void WriteErrorLine(string message)
        {
            OnWriteError?.Invoke(message);
        }

        public override void WriteLine(string message)
        {
            OnWriteOutput?.Invoke(message);
        }

        public override void WriteVerboseLine(string message)
        {
            OnWriteVerbose?.Invoke(message);
        }

        public override void WriteWarningLine(string message)
        {
            OnWriteWarning?.Invoke(message);
        }
    }
}

// ReSharper restore MemberCanBePrivate.Global
// ReSharper restore UnusedMember.Global