namespace DeploymentTool
{
    public interface IDeploymentToolTask
    {
        DeploymentTaskResult InputParametersAreValid(DeploymentTaskParameters taskParameters);
        DeploymentTaskResult TaskWork(DeploymentTaskParameters taskParameters);
    }
}