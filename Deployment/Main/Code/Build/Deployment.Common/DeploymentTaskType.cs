namespace Deployment.Common
{
    public enum DeploymentTaskType
    {
        None = 0,
        Pre,
        Post,
        PostLab,
        Package,
        Preview,
        Encrypt,
        Decrypt
    }
}