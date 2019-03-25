using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsLifecycle.Register, "LogFile", DefaultParameterSetName = "New")]
    public class RegisterLogFileCommand : PSCmdlet
    {
        private string _path;

        [Parameter(ParameterSetName = "AttachExisting",
            Mandatory = true,
            Position = 0, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
        public LogFile InputObject { get; set; }

        [Parameter(Mandatory = true,
            Position = 0,
            ParameterSetName = "New", ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
        public string Path
        {
            get { return _path; }
            set
            {
                _path = GetUnresolvedProviderPathFromPSPath(value);
            }
        }

        [Parameter(ParameterSetName = "New")]
        public string Title { get; set; }

        [Parameter(ParameterSetName = "New")]
        public ScriptBlock OnError { get; set; }

        [Parameter(ParameterSetName = "New")]
        public StreamType StreamType { get; set; } = StreamType.All;

        [Parameter(ParameterSetName = "New")]
        public SwitchParameter Append { get; set; }

        [Parameter(ParameterSetName = "New")]
        public SwitchParameter WithHeader { get; set; }

        [Parameter]
        public SwitchParameter LogTimestamp { get; set; }

        [Parameter]
        public SwitchParameter NoConsole { get; set; }

        [Parameter]
        public SwitchParameter NoLog { get; set; }

        protected override void ProcessRecord() {
            var hostInterceptor = HostIoInterceptor.Instance;

            var runspaceId = Runspace.DefaultRunspace.InstanceId;

           var isLogRegistered = hostInterceptor.IsRunspaceLogRegistered(runspaceId, ParameterSetName == "New" ? Path : InputObject.Path);

            var logFile = ParameterSetName == "New"
                ? new LogFile(Path, StreamType, OnError) { Paused = NoLog, LogTimestamp = LogTimestamp }
                : isLogRegistered
                ? InputObject
                : new LogFile(InputObject.Path, InputObject.Streams, InputObject.ErrorCallback) { Paused = NoLog, LogTimestamp = LogTimestamp };

            hostInterceptor.AttachToHost(CommandRuntime);
            hostInterceptor.AddSubscriber(runspaceId, logFile);
            hostInterceptor.SupressConsole = NoConsole;

            if (ParameterSetName == "New") {
                ProcessHeaders(logFile);
            }

            WriteObject(logFile);
        }

        private void ProcessHeaders(IHostIoSubscriber logFile)
        {
            if (string.IsNullOrEmpty(Title))
            {
                //TODO: This does not alway work as it depends out how/what is being executed.
                var script = MyInvocation.ScriptName;
                var name = System.IO.Path.GetFileName(script);
                Title = name;
            }

            if (Append)
            {
                logFile.WriteEmptyLine(2);

                if(WithHeader)
                    logFile.WriteHeader(string.Format(Constants.SubHeader, Title, DateTime.Now.ToString("R")));
            }
            else
            {
                logFile.DeleteLog();

                if (WithHeader)
                    logFile.WriteHeader(string.Format(Constants.Header, DateTime.Now.ToString("R"), Environment.UserName, Environment.UserDomainName, Environment.MachineName, Environment.OSVersion, Title));
            }
        }
    }
}