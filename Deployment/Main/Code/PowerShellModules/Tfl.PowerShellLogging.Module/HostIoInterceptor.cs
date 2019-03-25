using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Host;
using System.Management.Automation.Runspaces;
using System.Reflection;
using System.Security;
using System.Text;

namespace TFL.PowerShell.Logging
{
    public class HostIoInterceptor : PSHostUserInterface
    {
        private PSHostUserInterface _externalUi;
        private PSHost _host;
        public static readonly HostIoInterceptor Instance = new HostIoInterceptor();
        private readonly List<WeakReference> _subscribers;
        private readonly StringBuilder _writeCache;
        private LogState _logState;
        private readonly IDictionary<Guid, bool> _pausedRunspaces;
        private static readonly object _lock = new object();
        private Runspace _proxyRunspace;

        private HostIoInterceptor()
        {
            _externalUi = null;
            _subscribers = new List<WeakReference>();
            _writeCache = new StringBuilder();
            _host = null;
            _pausedRunspaces = new Dictionary<Guid, bool>();
        }

        public void AttachProxyRunspace(Runspace runspace)
        {
            _proxyRunspace = runspace;
        }

        public bool StopWatch { get; set; }

        public bool SupressConsole
        {
            get
            {
                var runspaceId = _proxyRunspace?.InstanceId ?? Runspace.DefaultRunspace?.InstanceId;
                bool result;

                if (!runspaceId.HasValue)
                    return false;

                var exists = _pausedRunspaces.TryGetValue(runspaceId.Value, out result);
                return exists && result;
            }
            set
            {
                var runspaceId = _proxyRunspace?.InstanceId ?? Runspace.DefaultRunspace?.InstanceId;

                if(runspaceId.HasValue)
                    _pausedRunspaces[runspaceId.Value] = value;
            }
        }

        public bool IsRunspaceLogRegistered(Guid runspaceId, string logFilePath)
        {
            return Subscribers.Any(s => s.Path.Equals(logFilePath, StringComparison.InvariantCultureIgnoreCase));
        }
        public bool IsRunspaceLogRegistered(Guid runspaceId, IHostIoSubscriber logFile)
        {
            return Subscribers.Any(s => s.Equals(logFile) || s.Path.Equals(logFile.Path, StringComparison.InvariantCultureIgnoreCase));
        }
        public void SuspendLogging(IEnumerable<IHostIoSubscriber> subscribers)
        {
            Subscribers.Where(s => subscribers == null || subscribers.Any(l => l.Path.Equals(s.Path, StringComparison.InvariantCultureIgnoreCase)))
                .ForEach(s => s.Paused = true);
        }

        public void ResumeLogging(IEnumerable<IHostIoSubscriber> subscribers)
        {
            Subscribers.Where(s => subscribers == null || subscribers.Any(l => l.Path.Equals(s.Path, StringComparison.InvariantCultureIgnoreCase)))
                .ForEach(s => s.Paused = false);
        }

        public void DisableLogTimestamp(IEnumerable<IHostIoSubscriber> subscribers)
        {
            Subscribers.Where(s => subscribers == null || subscribers.Any(l => l.Path.Equals(s.Path, StringComparison.InvariantCultureIgnoreCase)))
                .ForEach(s => s.LogTimestamp = false);
        }

        public void EnableLogTimestamp(IEnumerable<IHostIoSubscriber> subscribers)
        {
            Subscribers.Where(s => subscribers == null || subscribers.Any(l => l.Path.Equals(s.Path, StringComparison.InvariantCultureIgnoreCase)))
                .ForEach(s => s.LogTimestamp = true);
        }

        public override PSHostRawUserInterface RawUI => _externalUi?.RawUI;

        public IEnumerable<IHostIoSubscriber> Subscribers
        {
            get {
                var runspaceId = _proxyRunspace?.InstanceId ?? Runspace.DefaultRunspace?.InstanceId;

                if (!runspaceId.HasValue)
                    return new List<IHostIoSubscriber>();

                lock (_lock)
                {
                    var subsribers = _subscribers?.Select(reference => (IHostIoSubscriber) reference.Target)
                        .Where(subscriber => subscriber != null && subscriber.RunspaceId.Equals(runspaceId.Value));
                    return subsribers ?? new List<IHostIoSubscriber>();
                }
            }
        }

        public void AttachToHost(ICommandRuntime runtime)
        {
            if (_host != null) { return; }
            if (runtime == null) { return; }

            const BindingFlags flags = BindingFlags.Instance | BindingFlags.NonPublic;

            object uiRef = runtime.Host.GetType().GetField("internalUIRef", flags)?.GetValue(runtime.Host);
            object ui = uiRef?.GetType().GetProperty("Value", flags)?.GetValue(uiRef, null);

            var externalUiField = ui?.GetType().GetField("externalUI", flags);

            if (externalUiField != null)
            {
                _externalUi = (PSHostUserInterface) externalUiField.GetValue(ui);
                externalUiField.SetValue(ui, this);
            }
            _host = runtime.Host;
        }

        public void DetachFromHost()
        {
            if (_host == null) { return; }

            const BindingFlags flags = BindingFlags.Instance | BindingFlags.NonPublic;

            var uiRef = _host.GetType().GetField("internalUIRef", flags)?.GetValue(_host);
            var ui = uiRef?.GetType().GetProperty("Value", flags)?.GetValue(uiRef, null);

            var externalUiField = ui?.GetType().GetField("externalUI", flags);

            if (externalUiField != null && externalUiField.GetValue(ui) == this)
            {
                externalUiField.SetValue(ui, _externalUi);
            }

            _externalUi = null;
            _host = null;
        }
        public void AddSubscriber(Guid runspaceId, IHostIoSubscriber subscriber)
        {
            lock (_lock)
            {
                if (IsRunspaceLogRegistered(runspaceId, subscriber))
                    return;

                _subscribers.Add(new WeakReference(subscriber));
            }
        }

        public void ClearSubscribers()
        {
            lock (_lock)
            {
                _subscribers.Clear();
            }
        }

        public void RemoveSubscribers(IEnumerable<IHostIoSubscriber> subscribers)
        {
            var data = subscribers.Select(s => new {s.Path});
            var runspaceId = _proxyRunspace?.InstanceId ?? Runspace.DefaultRunspace.InstanceId;

            lock (_lock)
            {
                var matches =
                    _subscribers
                        .Where(s => data.Any(
                            d => ((IHostIoSubscriber)s.Target).RunspaceId.Equals(runspaceId) &&
                                 d.Path.Equals(((IHostIoSubscriber)s.Target).Path, StringComparison.InvariantCultureIgnoreCase)))
                        .ToList();

                foreach (var reference in matches)
                {
                    var target = (IHostIoSubscriber)reference.Target;
                    //ensure to prevent logging straight away
                    target.Paused = true;
                    target.Dispose();
                    _subscribers.Remove(reference);
                }
            }
        }

        public override Dictionary<string, PSObject> Prompt(string caption, string message,
                                                            Collection<FieldDescription> descriptions)
        {
            if (_externalUi == null)
            {
                throw new InvalidOperationException();
            }

            var result = _externalUi.Prompt(caption, message, descriptions);

            SendToSubscribers(s => s.Prompt(result));

            return result;
        }

        public override int PromptForChoice(string caption, string message,
                                            Collection<ChoiceDescription> choices,
                                            int defaultChoice)
        {
            if (_externalUi == null)
            {
                throw new InvalidOperationException();
            }

            var result = _externalUi.PromptForChoice(caption, message, choices, defaultChoice);

            SendToSubscribers(s => s.ChoicePrompt(choices[result]));

            return result;
        }

        public override PSCredential PromptForCredential(string caption,
                                                         string message,
                                                         string userName,
                                                         string targetName)
        {
            if (_externalUi == null)
            {
                throw new InvalidOperationException();
            }

            var result = _externalUi.PromptForCredential(caption, message, userName, targetName);

            SendToSubscribers(s => s.CredentialPrompt(result));

            return result;
        }

        public override PSCredential PromptForCredential(string caption,
                                                         string message,
                                                         string userName,
                                                         string targetName,
                                                         PSCredentialTypes allowedCredentialTypes,
                                                         PSCredentialUIOptions options)
        {
            if (_externalUi == null)
            {
                throw new InvalidOperationException();
            }

            var result = _externalUi.PromptForCredential(caption,
                                                                       message,
                                                                       userName,
                                                                       targetName,
                                                                       allowedCredentialTypes,
                                                                       options);

            SendToSubscribers(s => s.CredentialPrompt(result));

            return result;
        }

        public override string ReadLine()
        {
            if (_externalUi == null)
            {
                throw new InvalidOperationException();
            }

            var result = _externalUi.ReadLine();

            SendToSubscribers(s => s.ReadFromHost(result));

            return result;
        }

        public override SecureString ReadLineAsSecureString()
        {
            if (_externalUi == null)
                throw new InvalidOperationException();

            return _externalUi.ReadLineAsSecureString();
        }

        public void DeleteLogs()
        {
            foreach (var hostIoSubscriber in Subscribers)
            {
                hostIoSubscriber.DeleteLog();
            }
        }

        public override void Write(string value)
        {
            if (_externalUi == null)
                throw new InvalidOperationException();

            lock (_lock)
            {
                SendToConsole(s => s.Write(value));
                _writeCache.Append(value);
            }
        }

        public override void Write(ConsoleColor foregroundColor, ConsoleColor backgroundColor, string value)
        {
            if (_externalUi == null)
                throw new InvalidOperationException();

            lock (_lock)
            {
                SendToConsole(s => s.Write(foregroundColor, backgroundColor, value));
                _writeCache.Append(value);
            }
        }

        public override void WriteDebugLine(string value)
        {
            if (_externalUi == null)
            {
                throw new InvalidOperationException();
            }

            lock (_lock)
            {
                SendToConsole(s => s.WriteDebugLine(value));

                var lines = value.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);
                foreach (var line in lines)
                {
                    _writeCache.AppendLine(line);
                }

                SendToSubscribers(s => s.WriteDebugLine(_writeCache.ToString()));
            }
        }

        public override void WriteErrorLine(string value)
        {
            if (_externalUi == null)
            {
                throw new InvalidOperationException();
            }

            //as we are using WriteLine, ensure to trim off an carriage returns etc.
            var temp = value.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None)[0];
            lock (_lock)
            {
                SendToConsole(s => s.WriteErrorLine(temp));
                _writeCache.AppendLine(temp);
                SendToSubscribers(s => s.WriteErrorLine(_writeCache.ToString()));
            }
        }

        public override void WriteLine()
        {
            if (_externalUi == null)
            {
                throw new InvalidOperationException();
            }

            lock (_lock)
            {
                SendToConsole(s => s.WriteLine());
                SendToSubscribers(s => s.WriteLine(_writeCache.ToString()));
            }
        }

        public override void WriteLine(string value)
        {
            if (_externalUi == null)
            {
                throw new InvalidOperationException();
            }

            lock (_lock)
            {
                SendToConsole(s => s.WriteLine(value));
                _writeCache.AppendLine(value);
                SendToSubscribers(s => s.WriteLine(_writeCache.ToString()));
            }
        }

        public override void WriteLine(ConsoleColor foregroundColor, ConsoleColor backgroundColor, string value)
        {
            if (_externalUi == null)
            {
                throw new InvalidOperationException();
            }

            //as we are using WriteLine, ensure to trim off an carriage returns etc.
            var temp = value.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None)[0];

            lock (_lock)
            {
                SendToConsole(s => s.WriteLine(foregroundColor, backgroundColor, temp));
                _writeCache.AppendLine(temp);
                SendToSubscribers(s => s.WriteLine(_writeCache.ToString()));
            }
        }

        public override void WriteProgress(long sourceId, ProgressRecord record)
        {
            if (_externalUi == null)
            {
                throw new InvalidOperationException();
            }

            SendToConsole(s => s.WriteProgress(sourceId, record), true);
        }

        public override void WriteVerboseLine(string value)
        {
            if (_externalUi == null)
            {
                throw new InvalidOperationException();
            }

            lock (_lock)
            {

                SendToConsole(s => s.WriteVerboseLine(value));

                var lines = value.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);
                foreach (var line in lines)
                {
                    _writeCache.AppendLine(line);
                }

                SendToSubscribers(s => s.WriteVerboseLine(_writeCache.ToString()));
            }
        }

        public override void WriteWarningLine(string value)
        {
            if (_externalUi == null)
            {
                throw new InvalidOperationException();
            }

            //as we are using WriteLine, ensure to trim off an carriage returns etc.
            var temp = value.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None)[0];
            lock (_lock)
            {

                SendToConsole(s => s.WriteWarningLine(temp));
                _writeCache.AppendLine(temp);
                SendToSubscribers(s => s.WriteWarningLine(_writeCache.ToString()));
            }
        }

        public override void WriteInformation(InformationRecord record)
        {
            if (record.Tags.Contains(Constants.NoTimestamp))
                _logState = _logState | LogState.NoTimestamp;

            if (record.Tags.Contains(Constants.NoConsole))
                _logState = _logState | LogState.NoConsole;

            if (record.Tags.Contains(Constants.NoLog))
                _logState = _logState | LogState.NoLog;

            if (record.Tags.Contains(Constants.CacheLog))
                _logState = _logState | LogState.CacheLog;

            base.WriteInformation(record);
        }

        private void SendToSubscribers(Action<IHostIoSubscriber> action)
        {
            //start by ensuring we have no dead references
            lock(_lock)
            {
                var deadReferences = _subscribers.Where(s => s.Target == null).ToList();

                foreach (var reference in deadReferences)
                {
                    _subscribers.Remove(reference);
                }

                foreach (var subscriber in Subscribers)
                {
                    if (subscriber.Paused || _logState.HasFlag(LogState.NoLog))
                        continue;

                    var logTimeStamp = subscriber.LogTimestamp;
                    var cacheLog = subscriber.CacheLog;

                    if (_logState.HasFlag(LogState.NoTimestamp))
                        subscriber.LogTimestamp = false;

                    if (_logState.HasFlag(LogState.CacheLog))
                        subscriber.CacheLog = true;

                    action?.Invoke(subscriber);
                    subscriber.LogTimestamp = logTimeStamp;
                    subscriber.CacheLog = cacheLog;
                }

                _writeCache.Length = 0;
            }

            _logState = 0;
        }

        private void SendToConsole(Action<PSHostUserInterface> action, bool isProgress = false)
        {
            var noConsole = (!isProgress && SupressConsole) || _logState.HasFlag(LogState.NoConsole);

            if (noConsole)
                return;

            action?.Invoke(_externalUi);
        }
    }
}