using System;
using System.Text;
using Deployment.Common.Helpers;

namespace Deployment.Common {

    public static class ExceptionExtensions {

        public static string BuildExceptionMessage(this Exception exception, string message) {

            ArgumentHelper.AssertNotNull(exception, "exception");
            var clone = exception;

            var sb = new StringBuilder();

            if(!string.IsNullOrEmpty(message))
                sb.AppendLine(message);

            var aggregateException = clone as AggregateException;

            if(aggregateException != null) {
                foreach(var ex in aggregateException.Flatten().InnerExceptions) {
                    sb.AppendFormat("{0} : ", ex.GetType().FullName)
                        .AppendLine("Message :" + ex.Message)
                        .AppendLine("Source :" + ex.Source)
                        .AppendLine("Stack Trace :" + ex.StackTrace)
                        .AppendLine("TargetSite :" + ex.TargetSite);
                }
            }
            else {
                while(clone != null) {
                    sb.AppendFormat("{0} : ", clone.GetType().FullName)
                        .AppendLine("Message :" + clone.Message)
                        .AppendLine("Source :" + clone.Source)
                        .AppendLine("Stack Trace :" + clone.StackTrace)
                        .AppendLine("TargetSite :" + clone.TargetSite);

                    clone = clone.InnerException;

                    if(clone != null) {
                        sb.AppendLine("--- INNER EXCEPTION ---");
                    }
                }
            }

            return sb.ToString();
        }

        public static string BuildExceptionMessage(this Exception exception) {

            return BuildExceptionMessage(exception, null);
        }

        public static string GetDeepMessage(this Exception exception) {
            if(exception == null) {
                return string.Empty;
            }

            return exception.InnerException != null ? GetDeepMessage(exception.InnerException) : exception.Message;
        }
    }
}