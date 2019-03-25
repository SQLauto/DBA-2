using System;
using System.Collections.Generic;
using System.Runtime.Serialization;

namespace Deployment.Common.Exceptions
{
    [Serializable]
    public class ValidationException : Exception
    {
        private readonly IList<string> _validationErrors = new List<string>();

        public ValidationException()
        {

        }

        public ValidationException(string message) : base(message)
        {

        }

        public ValidationException(string message, Exception innerException) : base(message, innerException)
        {

        }

        protected ValidationException(SerializationInfo serializationInfo, StreamingContext context) : base(serializationInfo, context)
        {

        }

        public IList<string> ValidationErrors { get { return _validationErrors; } }
    }
}