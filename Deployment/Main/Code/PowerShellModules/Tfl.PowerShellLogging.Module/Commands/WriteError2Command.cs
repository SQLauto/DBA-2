using System;
using System.Collections.Generic;
using System.IO;
using System.Management.Automation;
using System.Management.Automation.Host;
using System.Text;
using Microsoft.PowerShell.Commands;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsCommunications.Write, "Error2", RemotingCapability = RemotingCapability.None, DefaultParameterSetName = "NoException")]
    public class WriteError2Command : ConsoleColorCmdlet
    {
        [Parameter(Mandatory = true, ParameterSetName = "WithException")]
        public Exception Exception { get; set; }

        [Parameter(Mandatory = true, ParameterSetName = "NoException", Position = 0, ValueFromPipeline = true)]
        [Parameter(ParameterSetName = "WithException")]
        [AllowNull]
        [AllowEmptyString]
        [Alias("Msg")]
        public string Message { get; set; }

        [Parameter(Mandatory = true, ParameterSetName = "ErrorRecord")]
        public ErrorRecord ErrorRecord { get; set; }

        [Parameter(ParameterSetName = "ErrorRecord")]
        [AllowNull]
        [AllowEmptyString]
        public string ErrorMessage { get; set; }

        [Parameter(ParameterSetName = "NoException")]
        [Parameter(ParameterSetName = "WithException")]
        public ErrorCategory Category { get; set; }

        [Parameter(ParameterSetName = "NoException")]
        [Parameter(ParameterSetName = "WithException")]
        public string ErrorId { get; set; }

        [Parameter(ParameterSetName = "WithException")]
        [Parameter(ParameterSetName = "NoException")]
        public object TargetObject { get; set; }

        [Parameter]
        public string RecommendedAction { get; set; }

        [Parameter]
        [Alias("Activity")]
        public string CategoryActivity { get; set; }

        [Parameter]
        [Alias("Reason")]
        public string CategoryReason { get; set; }

        [Parameter]
        [Alias("TargetName")]
        public string CategoryTargetName { get; set; }

        [Parameter]
        [Alias("TargetType")]
        public string CategoryTargetType { get; set; }

        [Parameter]
        public SwitchParameter NoConsole { get; set; }

        [Parameter]
        public SwitchParameter NoLog { get; set; }

        protected override void ProcessRecord()
        {
            if (!IsForegroundColorSet)
                ForegroundColor = ConsoleColor.Red;

            var message = ProcessMessage();

            var informationMessage = new HostInformationMessage
            {
                Message = message,
            };

            try
            {
                informationMessage.ForegroundColor = ForegroundColor;
                informationMessage.BackgroundColor = BackgroundColor;
            }
            catch (HostException)
            {
            }

            var tags = new List<string> {Constants.PsHost, Constants.NoTimestamp};

            if (NoLog)
                tags.Add(Constants.NoLog);

            if (NoConsole)
                tags.Add(Constants.NoConsole);

            WriteInformation(informationMessage, tags.ToArray());
        }

        private string ProcessMessage()
        {
            var builder = new StringBuilder();

            switch (ParameterSetName)
            {
                case "NoException":
                    if (string.IsNullOrWhiteSpace(Message))
                    {
                        Message = "An error has occurred.";
                    }

                    builder.Append("Error: ").Append(Message);
                    break;


                default:

                    ErrorRecord errorRecord;

                    if (ErrorRecord != null)
                    {
                        errorRecord = new ErrorRecord(ErrorRecord, null);
                    }
                    else
                    {
                        var exception = Exception ?? new WriteErrorException(Message);

                        if (string.IsNullOrEmpty(ErrorId))
                            ErrorId = exception.GetType().FullName;

                        errorRecord = new ErrorRecord(exception, ErrorId, Category, TargetObject);

                        if (Exception != null && !string.IsNullOrEmpty(Message))
                            errorRecord.ErrorDetails = new ErrorDetails(Message);
                    }

                    if (!string.IsNullOrEmpty(RecommendedAction))
                    {
                        if (errorRecord.ErrorDetails == null)
                            errorRecord.ErrorDetails = new ErrorDetails(errorRecord.ToString());

                        errorRecord.ErrorDetails.RecommendedAction = RecommendedAction;
                    }

                    if (!string.IsNullOrEmpty(CategoryActivity))
                        errorRecord.CategoryInfo.Activity = CategoryActivity;

                    if (!string.IsNullOrEmpty(CategoryReason))
                        errorRecord.CategoryInfo.Reason = CategoryReason;

                    if (!string.IsNullOrEmpty(CategoryTargetName))
                        errorRecord.CategoryInfo.TargetName = CategoryTargetName;

                    if (!string.IsNullOrEmpty(CategoryTargetType))
                        errorRecord.CategoryInfo.TargetType = CategoryTargetType;

                    var invocationInfo = GetVariableValue("MyInvocation") as InvocationInfo;

                    if (invocationInfo != null)
                        errorRecord.CategoryInfo.Activity = "Write-Error2";

                    if (!string.IsNullOrWhiteSpace(ErrorMessage))
                        builder.Append("Error: ").AppendLine(ErrorMessage);

                    builder.Append(string.Concat("Error: ", errorRecord.ToString()));

                    if (!string.IsNullOrWhiteSpace(invocationInfo?.ScriptName))
                        builder.Append(Environment.NewLine).Append("\tScript Name: ").Append(Path.GetFileName(invocationInfo.ScriptName));

                    if (!string.IsNullOrEmpty(errorRecord.ScriptStackTrace))
                        builder.Append(Environment.NewLine).Append("\tScript StackTrace: ").Append(errorRecord.ScriptStackTrace);

                    var aggregateException = errorRecord.Exception as AggregateException;

                    if (aggregateException != null)
                    {
                        foreach (var ex in aggregateException.Flatten().InnerExceptions)
                        {
                            builder.Append(Environment.NewLine).Append("\tException :" + ex.GetType().FullName)
                                .Append(Environment.NewLine).Append("\tSource :" + ex.Source)
                                .Append(Environment.NewLine).Append("\tStackTrace :" + ex.StackTrace);
                        }
                    }
                    else
                    {
                        var exception = errorRecord.Exception;

                        while (exception != null)
                        {
                            builder.Append(Environment.NewLine).Append("\tException: " + exception.GetType().FullName)
                                .Append(Environment.NewLine).Append("\tSource: " + exception.Source)
                                .Append(Environment.NewLine).Append("\tStackTrace: " + exception.StackTrace);

                            exception = exception.InnerException;

                            if (exception != null)
                            {
                                builder.Append(Environment.NewLine).Append("\t--- INNER EXCEPTION ---");
                            }
                        }
                    }

                    errorRecord.ErrorDetails = new ErrorDetails(builder.ToString());

                    break;
            }

            return builder.ToString();
        }
    }
}