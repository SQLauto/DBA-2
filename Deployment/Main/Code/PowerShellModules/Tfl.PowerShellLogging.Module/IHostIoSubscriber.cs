using System;
using System.Collections.Generic;
using System.Management.Automation;
using System.Management.Automation.Host;

namespace TFL.PowerShell.Logging
{
    /// <summary>
    ///     The Logger interface.
    /// </summary>
    public interface IHostIoSubscriber : IDisposable {

        // These methods intercept input, which is not really useful for the type of logging I intend this module to perform.
        // The script that called these methods will already have access to the results, and the script author can choose
        // to display it or not (at which point it will be caught by the logging module).
        //
        // WriteProgress is also included in this unused category, because this doesn't seem to make much sense in a log file.

        void ChoicePrompt(ChoiceDescription choice);
        void CredentialPrompt(PSCredential credential);
        void Prompt(Dictionary<string, PSObject> returnValue);
        void ReadFromHost(string inputText);
        void WriteProgress(long sourceId, ProgressRecord record);
        void WriteDebugLine(string message);
        void WriteErrorLine(string message);
        void WriteLine(string message);
        void Write(string message);
        void WriteHeader(string message);
        void WriteVerboseLine(string message);
        void WriteWarningLine(string message);
        void WriteEmptyLine(int lineCount = 1);
        void DeleteLog();
        bool Paused { get; set; }
        bool LogTimestamp { get; set; }
        string Path { get; }
        Guid RunspaceId { get; }
        bool CacheLog { get; set; }
    }
}