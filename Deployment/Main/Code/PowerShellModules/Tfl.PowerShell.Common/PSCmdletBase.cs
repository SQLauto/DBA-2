using System;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Reflection;
using System.Text;

namespace Tfl.PowerShell.Common
{
    public abstract class PSCmdletBase : PSCmdlet
    {
        public const string PsHost = "PSHOST";

        protected override void BeginProcessing()
        {
            base.BeginProcessing();

            SetDefaultValues();
        }

        protected virtual void SetDefaultValues()
        {
            var propertyInfos = GetType().GetProperties(BindingFlags.Public | BindingFlags.FlattenHierarchy | BindingFlags.Instance)
              .Where
              (
                propertyInfo => !MyInvocation.BoundParameters.ContainsKey(propertyInfo.Name)
                    && Attribute.GetCustomAttributes(propertyInfo, typeof(ParameterAttribute)).Any()
              );

            foreach (var propertyInfo in propertyInfos)
            {
                // only process Parameter with a PSDefaultValue
                var psDefaultValueAttribute = (PSDefaultValueAttribute)Attribute.GetCustomAttribute(propertyInfo, typeof(PSDefaultValueAttribute));
                if (null == psDefaultValueAttribute)
                {
                    continue;
                }

                propertyInfo.SetValue(this, psDefaultValueAttribute.Value, null);
            }
        }

        protected virtual void WriteHost(string message)
        {
            var informationMessage = new HostInformationMessage
            {
                Message = message
            };

            var tags = new[] { PsHost };

            WriteInformation(informationMessage, tags);
        }

        protected virtual void WriteHost(string message, params object[] parameters)
        {
            var informationMessage = new HostInformationMessage
            {
                Message = string.Format(message, parameters),
            };

            var tags = new[] { PsHost };

            WriteInformation(informationMessage, tags);
        }

        protected virtual void WriteError<TException>(TException exception, object target, ErrorCategory category = ErrorCategory.NotSpecified, bool throwTerminating = false) where TException : Exception
        {
            var invocationInfo = GetVariableValue("MyInvocation") as InvocationInfo;

            var errorRecord = BuildErrorRecord(invocationInfo, exception, category, target);

            if (throwTerminating)
                ThrowTerminatingError(errorRecord);
            else
                WriteError(errorRecord);
        }

        protected virtual ErrorRecord BuildErrorRecord(InvocationInfo invocationInfo, Exception exception, ErrorCategory category, object target)
        {
            var errorId = exception.GetType().FullName;
            var errorRecord = new ErrorRecord(exception, errorId, category, target);

            var clone = exception;

            var builder = new StringBuilder();

            builder.Append(errorRecord);

            if (!string.IsNullOrWhiteSpace(invocationInfo?.ScriptName))
                builder.Append(Environment.NewLine).Append("\tScript Name: ").Append(Path.GetFileName(invocationInfo.ScriptName ?? "None"));

            if (!string.IsNullOrEmpty(errorRecord.ScriptStackTrace))
                builder.Append(Environment.NewLine).Append("\tScript StackTrace: ").Append(errorRecord.ScriptStackTrace ?? "None");

            if (errorRecord.CategoryInfo!=null)
                builder.Append(Environment.NewLine).Append("\tError Category: ").Append(errorRecord.CategoryInfo?.Category);

            var aggregateException = clone as AggregateException;

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
                while (clone != null)
                {
                    builder.Append(Environment.NewLine).Append("\tException: " + clone.GetType().FullName)
                        .Append(Environment.NewLine).Append("\tSource: " + clone.Source)
                        .Append(Environment.NewLine).Append("\tStackTrace: " + clone.StackTrace);

                    clone = clone.InnerException;

                    if (clone != null)
                    {
                        builder.Append(Environment.NewLine).Append("\t--- INNER EXCEPTION ---");
                    }
                }
            }

            errorRecord.ErrorDetails = new ErrorDetails(builder.ToString());

            return errorRecord;
        }

        protected virtual string BuildErrorMessage(InvocationInfo invocationInfo, Exception exception, string message, ErrorCategory category, object target)
        {
            var builder = new StringBuilder();

            var errorId = exception.GetType().FullName;

            var errorRecord = new ErrorRecord(exception, errorId, category, target);

            if (!string.IsNullOrEmpty(message))
                errorRecord.ErrorDetails = new ErrorDetails(message);

            if (invocationInfo != null)
                errorRecord.CategoryInfo.Activity = "Write-Error";

            if (!string.IsNullOrWhiteSpace(message))
                builder.Append("Error: ").AppendLine(message);

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
                var ex = exception;

                while (ex != null)
                {
                    builder.Append(Environment.NewLine).Append("\tException: " + ex.GetType().FullName)
                        .Append(Environment.NewLine).Append("\tSource: " + ex.Source)
                        .Append(Environment.NewLine).Append("\tStackTrace: " + ex.StackTrace);

                    ex = ex.InnerException;

                    if (ex != null)
                    {
                        builder.Append(Environment.NewLine).Append("\t--- INNER EXCEPTION ---");
                    }
                }
            }

            errorRecord.ErrorDetails = new ErrorDetails(builder.ToString());

            return builder.ToString();
        }
    }
}