using System.Management.Automation;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsCommon.Get, "LogFile")]
    public class GetLogFileCommand : PSCmdlet
    {
        private string _path;

        [Parameter(Mandatory = false,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true)]
        [ValidateNotNullOrEmpty]
        public string Path
        {
            get { return _path; }
            set
            {
                _path = GetUnresolvedProviderPathFromPSPath(value);
            }
        }

        protected override void EndProcessing()
        {
            var interceptor = HostIoInterceptor.Instance;

            foreach(var subscriber in interceptor.Subscribers)
            {
                var logFile = subscriber as LogFile;

                if (logFile != null &&
                    (_path == null || System.IO.Path.GetFullPath(logFile.Path) == System.IO.Path.GetFullPath(_path)))
                {
                    WriteObject(logFile);
                }
            }
        }
    }
}