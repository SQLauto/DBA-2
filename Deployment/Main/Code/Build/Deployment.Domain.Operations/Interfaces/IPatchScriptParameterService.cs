namespace Deployment.Domain.Operations
{
    public interface IPatchScriptParameterService
    {
        void WritePatchScriptParameterFile(string targetFile, string defaultConfig, string overrideConfig, string rigName = null, string rigConfigFile = null);

        void WritePatchScriptRunFile(string scriptRoot, string targetFile, string sourceFile, string dropFolder,
            string targetDatabase, string dataSource, string helperScriptsPath, string parameterFile, string environment, string driveLetter);
    }
}