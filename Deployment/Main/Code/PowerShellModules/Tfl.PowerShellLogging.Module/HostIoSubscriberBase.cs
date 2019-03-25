using System;
using System.Collections.Generic;
using System.Management.Automation;
using System.Management.Automation.Host;

namespace TFL.PowerShell.Logging {
    public abstract class HostIoSubscriberBase : IHostIoSubscriber {
        public virtual void Dispose() { }

        public virtual void ChoicePrompt(ChoiceDescription choice) {
        }

        public virtual void CredentialPrompt(PSCredential credential) {
        }

        public virtual void Prompt(Dictionary<string, PSObject> returnValue) {
        }

        public virtual void ReadFromHost(string inputText) {
        }

        public virtual void WriteProgress(long sourceId, ProgressRecord record) {
        }

        public virtual void WriteDebugLine(string message) {
        }

        public virtual void WriteErrorLine(string message) {
        }

        public virtual void WriteLine(string message) {
        }

        public virtual void Write(string message)
        {
        }

        public virtual void WriteHeader(string message)
        {
        }

        public virtual void WriteVerboseLine(string message) {
        }

        public virtual void WriteWarningLine(string message) {
        }

        public virtual void WriteEmptyLine(int lineCount = 1) {
        }
        public virtual void DeleteLog() { }
        public bool Paused { get; set; }
        public bool LogTimestamp { get; set; }
        public string Path { get; protected set; }
        public Guid RunspaceId { get; protected set; }
        public bool CacheLog { get; set; }
    }
}