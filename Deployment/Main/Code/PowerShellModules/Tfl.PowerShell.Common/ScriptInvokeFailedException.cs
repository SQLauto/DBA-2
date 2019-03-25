using System;
using System.Runtime.Serialization;

namespace Tfl.PowerShell.Common
{
    [Serializable]
    public class ScriptInvokeFailedException : Exception
    {
        public ScriptInvokeFailedException()
        {
        }

        public ScriptInvokeFailedException(string message) : base(message)
        {
        }

        public ScriptInvokeFailedException(string message, Exception innerException) : base(message, innerException)
        {
        }

        protected ScriptInvokeFailedException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}