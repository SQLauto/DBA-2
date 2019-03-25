using System;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using System.Management.Automation.Host;
using System.Text;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsCommunications.Write, "Host2", RemotingCapability = RemotingCapability.None, DefaultParameterSetName = "Default")]
    public class WriteHost2Command : ConsoleColorCmdlet
    {
        [Parameter(Position = 0, ValueFromPipeline = true, ValueFromRemainingArguments = true, ParameterSetName = "Default")]
        public object Object { get; set; }

        [Parameter(ParameterSetName = "Default")]
        public object Separator { get; set; } = " ";

        [Parameter(Position = 0, ParameterSetName = "Status")]
        public StatusType Type { get; set; }

        [Parameter(ParameterSetName = "Status")]
        public string Prefix { get; set; }

        [Parameter(ParameterSetName = "Status")]
        public string Message { get; set; }

        [Parameter]
        public TimeSpan? Elapsed { get; set; }

        [Parameter]
        public SwitchParameter NoConsole { get; set; }

        [Parameter]
        public SwitchParameter NoLog { get; set; }

        [Parameter]
        public SwitchParameter NoTimestamp { get; set; }

        [Parameter]
        public SwitchParameter NoNewline { get; set; }

        [Parameter]
        public SwitchParameter CacheLog { get; set; }

        protected override void ProcessRecord()
        {
            var resultText = ProcessStatus() ?? string.Empty;

            var informationMessage = new HostInformationMessage
            {
                Message = resultText,
                NoNewLine = NoNewline.IsPresent
            };

            try
            {
                informationMessage.ForegroundColor = ForegroundColor;
                informationMessage.BackgroundColor = BackgroundColor;
            }
            catch (HostException)
            {
            }

            var tags = new List<string> { Constants.PsHost };

            if (NoLog)
                tags.Add(Constants.NoLog);

            if (NoConsole)
                tags.Add(Constants.NoConsole);

            if (NoTimestamp)
                tags.Add(Constants.NoTimestamp);

            if (CacheLog)
                tags.Add(Constants.CacheLog);

            WriteInformation(informationMessage, tags.ToArray());
        }

        private string ProcessObject(object inputObject)
        {
            if (inputObject == null)
                return null;

            var objectAsString = inputObject as string;
            if (objectAsString?.Length > 0)
                return objectAsString;

            IEnumerable enumerable;
            if ((enumerable = inputObject as IEnumerable) != null)
            {
                var flag = false;
                var stringBuilder = new StringBuilder();
                foreach (var item in enumerable)
                {
                    if (flag && Separator != null)
                        stringBuilder.Append(Separator);
                    stringBuilder.Append(ProcessObject(item));
                    flag = true;
                }
                return stringBuilder.ToString();
            }

            objectAsString = inputObject.ToString();

            return objectAsString.Length > 0 ? objectAsString : null;
        }

        private string ProcessStatus()
        {
            string message;

            var script = MyInvocation.ScriptName;
            var name = System.IO.Path.GetFileName(script);

            var suffix = string.Empty;

            if (Elapsed.HasValue && Elapsed.Value != TimeSpan.MinValue)
            {
                var ms = Elapsed.Value.Milliseconds;
                var sec = Elapsed.Value.Seconds;
                var min = Elapsed.Value.Minutes;

                suffix = Elapsed.Value.TotalMinutes > 2.0
                    ? $" (Elapsed time {min:d2}:{sec:d2}.{ms:d2} minutes)"
                    : $" (Elapsed time {Elapsed.Value.TotalSeconds:F2} seconds)";
            }

            switch (Type)
            {
                case StatusType.Success:
                    NoTimestamp = true;
                    if (string.IsNullOrWhiteSpace(Message))
                        Message = "Finished executing script " + name;

                    message = (string.IsNullOrEmpty(Prefix) ? "Success: " : Prefix) + Message;
                    if (!IsForegroundColorSet)
                        ForegroundColor = ConsoleColor.Green;
                    break;
                case StatusType.Failure:
                    NoTimestamp = true;
                    if (string.IsNullOrWhiteSpace(Message))
                        Message = "Finished executing script " + name;

                    message = (string.IsNullOrEmpty(Prefix) ? "Failure: " : Prefix) + Message;
                    if (!IsForegroundColorSet)
                        ForegroundColor = ConsoleColor.Red;
                    break;
                case StatusType.Error:
                    NoTimestamp = true;
                    message = (string.IsNullOrEmpty(Prefix) ? "Error: " : Prefix) + Message;
                    if (!IsForegroundColorSet)
                        ForegroundColor = ConsoleColor.Red;
                    break;
                case StatusType.Warning:
                    NoTimestamp = true;
                    message = (string.IsNullOrEmpty(Prefix) ? "Warning: " : Prefix) + Message;
                    if (!IsForegroundColorSet)
                        ForegroundColor = ConsoleColor.Yellow;
                    break;
                case StatusType.Progress:
                    message = (string.IsNullOrEmpty(Prefix) ? "Progress: " : Prefix) + Message;
                    break;
                default:
                    message = ProcessObject(Object);
                    break;
            }

            return message + suffix;
        }
    }
}