namespace DeploymentTool
{
    public enum DeploymentTaskType
    {
        None=0,
        Deploy,
        Decrypt,
        Encrypt,
        Package,
        Preview,
        PreDeployTest,
        PostDeployTest,
        PostLabDeployTest
    }
}