using System;
using System.Globalization;
using System.Management.Automation;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsCommunications.Write, "Header")]
    public class WriteHeaderCommand : PSCmdlet
    {
        [Parameter(Mandatory = true,
            ValueFromPipeline = true,
            Position = 0)]
        public string Title { get; set; }
        [Parameter]
        public SwitchParameter OutConsole { get; set; }

        [Parameter]
        public SwitchParameter AsSubHeader { get; set; }

        [Parameter]
        public TimeSpan? Elapsed { get; set; }

        protected override void ProcessRecord()
        {
            var suffix = string.Empty;

            if (Elapsed.HasValue && Elapsed.Value != TimeSpan.MinValue)
            {
                var ms = Elapsed.Value.Milliseconds;
                var sec = Elapsed.Value.Seconds;
                var min = Elapsed.Value.Minutes;

                suffix = Elapsed.Value.TotalMinutes > 2.0
                    ? $"(Elapsed time: {min:d2}:{sec:d2}.{ms:d2} minutes)"
                    : $"(Elapsed time: {Elapsed.Value.TotalSeconds:F2} seconds)";
            }

            var message = AsSubHeader
                ? string.Format(Constants.SubHeader, Title, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture), suffix)
                : string.Format(Constants.Header, DateTime.Now.ToString("dd MMMM yyyy HH:mm:ss", CultureInfo.InvariantCulture), Environment.UserName,
                    Environment.UserDomainName, Environment.MachineName, Environment.OSVersion, Title);

            var informationMessage = new HostInformationMessage
            {
                Message = message,
            };

            var tags = OutConsole ? new[] {Constants.PsHost, Constants.NoTimestamp} : new[] { Constants.PsHost, Constants.NoTimestamp, Constants.NoConsole };

            WriteInformation(informationMessage, tags);
        }
    }
}