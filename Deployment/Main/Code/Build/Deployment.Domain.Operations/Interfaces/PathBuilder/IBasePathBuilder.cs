namespace Deployment.Domain.Operations
{
    public interface IBasePathBuilder
    {
        bool IsLocalDebugMode { get; set; }
        string OutputDirectory { get; set; }
        string LoggingDirectory { get; set; }
    }
}