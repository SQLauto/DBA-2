namespace Deployment.Common.Helpers
{
    public interface ICommandLineHelper
    {
        string GetCommandLineParameter(string commandLine, string parameterName);
        string GetCommandLineParameterPathWithoutTrailingSlash(string commandLine, string parameterName);
        int PowershellCommand(string cmdArgs);
        int RemotePowershellCommand(string remoteMachine, string cmdArgs, string userName, string pswd);
        int PsExecCommand(string remoteMachine, string cmdArgs, string userName, string pswd);
    }
}