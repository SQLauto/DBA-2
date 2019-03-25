using System;
using System.Collections.Generic;
using System.Runtime.Serialization;

namespace Deployment.Common.Exceptions
{
    [Serializable]
    public class VCloudException : Exception
    {
        private readonly IList<string> _validationErrors = new List<string>();
        public VCloudException()
        {
        }
        public VCloudException(string message) : base(message)
        {
        }
        public VCloudException(string message, Exception innerException) : base(message, innerException)
        {
        }
        protected VCloudException(SerializationInfo serializationInfo, StreamingContext context) : base(serializationInfo, context)
        {
        }
        public IList<string> ValidationErrors { get { return _validationErrors; } }
    }
}