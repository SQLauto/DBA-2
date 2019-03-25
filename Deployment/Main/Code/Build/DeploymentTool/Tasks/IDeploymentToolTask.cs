using Deployment.Common;
using Deployment.Domain.Operations;

namespace Deployment.Tool.Tasks
{
    public interface IDeploymentToolTask
    {
        DeploymentTaskType TaskType { get; }
        bool ValidateInputParameters(DeploymentOperationParameters toolParameters);
        bool TaskWork(DeploymentOperationParameters toolParameters);
    }
}