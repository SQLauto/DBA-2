using System;
using System.Runtime.Serialization;

namespace Deployment.Tool.Tasks
{
    [Serializable]
    public class DeploymentTaskException : Exception
    {
        public DeploymentTaskException()
        {
        }
        public DeploymentTaskException(string message) : base(message)
        {
        }
        public DeploymentTaskException(string message, Exception innerException) : base(message, innerException)
        {
        }
        protected DeploymentTaskException(SerializationInfo serializationInfo, StreamingContext context) : base(serializationInfo, context)
        {
        }
    }
}