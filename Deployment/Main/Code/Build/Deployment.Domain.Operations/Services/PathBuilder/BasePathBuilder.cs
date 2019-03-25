namespace Deployment.Domain.Operations.Services
{
    //References to Directories (full or relative) should be called xxxxDirectory .e.g D:\Temp\
    //References to FolderNames should be called xxxxFolder e.g. "Temp"
    //References to full file paths should be called xxxxPath e.g. "D:\Temp\File.xml"
    //References to file names should be called xxxxFileName e.g. "File.xml"
    public abstract class BasePathBuilder : IBasePathBuilder
    {
        public bool IsLocalDebugMode { get; set; }
        public string OutputDirectory { get; set; }
        public string LoggingDirectory { get; set; }
    }
}