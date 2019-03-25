using System;
using System.IO;
using System.Management.Automation;
using Deployment.Domain.Operations.Services;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Database.Commands
{
    [Cmdlet(VerbsCommon.New, "PatchScriptRunFile")]
    public class NewPatchScriptRunFile : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNullOrEmpty]
        public string ComputerName { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string ScriptPath { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string HelperScriptsPath { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string ParameterFilePath { get; set; }
        [Parameter(Mandatory = true)]
        public string Environment { get; set; }
        [Parameter(Mandatory = true)]
        public string DataSource { get; set; }
        [Parameter(Mandatory = true)]
        public string TargetDatabase { get; set; }
        [Parameter(Mandatory = true)]
        public string DropFolder { get; set; }
        [Parameter]
        public string SqlScriptToRunSuffix { get; set; }
        [Parameter]
        public string DriveLetter { get; set; }

        protected override void ProcessRecord()
        {
            try
            {
                var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);
                var patchScriptParameterService = new PatchScriptParameterService(logger);
                var resolvedPath = GetUnresolvedProviderPathFromPSPath(ScriptPath);

                var scriptItem = new FileInfo(resolvedPath);
                if (!scriptItem.Exists)
                {
                    var errorMessage = $"ScriptPath {resolvedPath} does not exist.";
                    throw new FileNotFoundException(errorMessage, resolvedPath);
                }

                WriteVerbose($"ScriptPath {ScriptPath} exists");

                var scriptRoot = scriptItem.Directory.Parent.FullName;
                var baseName = string.Concat(".", Path.GetFileNameWithoutExtension(resolvedPath));
                var extension = string.Concat(scriptItem.Extension, ".ToRun");

                var targetFile = string.IsNullOrWhiteSpace(SqlScriptToRunSuffix)
                    ? Path.Combine(scriptItem.DirectoryName, string.Concat(ComputerName, baseName, extension))
                    : Path.Combine(scriptItem.DirectoryName,
                        string.Concat(SqlScriptToRunSuffix, baseName, extension));

                patchScriptParameterService.WritePatchScriptRunFile(scriptRoot, targetFile, resolvedPath, DropFolder,
                    TargetDatabase, DataSource, HelperScriptsPath, ParameterFilePath, Environment, DriveLetter);

                WriteObject(targetFile);
            }
            catch (Exception ex)
            {
                var errorRecord = new ErrorRecord(ex, Guid.NewGuid().ToString(), ErrorCategory.ObjectNotFound, this);
                WriteError(errorRecord);
            }
        }
    }
}
