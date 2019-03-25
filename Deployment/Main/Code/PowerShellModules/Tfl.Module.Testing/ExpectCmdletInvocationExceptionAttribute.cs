using System;
using System.Diagnostics.Contracts;
using System.Globalization;
using System.Text.RegularExpressions;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Tfl.Module.Testing
{
    public class ExpectCmdletInvocationExceptionAttribute : ExpectedExceptionBaseAttribute
    {
        private const string ExpectedExceptionFullname = "System.Management.Automation.CmdletInvocationException";

        public string MessagePattern { get; set; }

        public ExpectCmdletInvocationExceptionAttribute()
        {
            // N/A
        }

        public ExpectCmdletInvocationExceptionAttribute(string messagePattern)
        {
            Contract.Requires(null != messagePattern);

            MessagePattern = messagePattern;
        }

        protected override void Verify(Exception exception)
        {
            string message;

            if (exception.GetType().FullName == ExpectedExceptionFullname)
            {
                if ((null == MessagePattern) || Regex.IsMatch(exception.Message, MessagePattern))
                {
                    return;
                }

                message = string.Format
                (
                    CultureInfo.InvariantCulture,
                    "Test method threw expected exception, but did not match pattern '{0}'. Exception message: {1}",
                    MessagePattern,
                    exception.Message
                );
                throw new Exception(message);
            }

            RethrowIfAssertException(exception);

            message = string.Format
            (
                CultureInfo.InvariantCulture,
                "Test method {0}.{1} threw exception {2}, but ExpectCmdletInvocationExceptionAttribute was expected. Exception message: {3}",
                TestContext.FullyQualifiedTestClassName,
                TestContext.TestName,
                exception.GetType().FullName,
                exception.Message
            );
            throw new Exception(message);
        }
    }
}