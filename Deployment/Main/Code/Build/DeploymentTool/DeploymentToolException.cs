using System;
using System.Runtime.Serialization;

namespace Deployment.Tool
{
    [Serializable]
    public class DeploymentToolException : Exception
    {
        public DeploymentToolException()
        {

        }

        public DeploymentToolException(string message) : base(message)
        {

        }

        public DeploymentToolException(string message, Exception innerException) : base(message, innerException)
        {

        }

        protected DeploymentToolException(SerializationInfo serializationInfo, StreamingContext context) : base(serializationInfo, context)
        {

        }
    }
}