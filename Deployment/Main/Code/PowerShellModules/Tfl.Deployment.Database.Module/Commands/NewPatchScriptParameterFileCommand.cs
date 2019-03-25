using System;
using System.Collections.Generic;
using System.IO;
using System.Management.Automation;
using System.Management.Automation.Host;
using Deployment.Domain.Operations.Services;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Database.Commands
{
    [Cmdlet(VerbsCommon.New, "PatchScriptParameterFile")]
    public class NewPatchScriptParameterFileCommand : ConsoleColorCmdlet
    {
        [Parameter(Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string Path { get; set; }
        [Parameter(Mandatory = true)]
        public string DropFolder { get; set; }
        [Parameter(Mandatory = true)]
        public string DefaultConfig { get; set; }
        [Parameter]
        public string OverrideConfig { get; set; }
        [Parameter]
        public string RigName { get; set; }
        [Parameter]
        public string RigConfigFile { get; set; }
        [Parameter]
        public string SqlScriptToRunSuffix { get; set; }

        protected override void ProcessRecord()
        {
            //try
            //{
            //    var resolvedPath = GetUnresolvedProviderPathFromPSPath(Path);

            //    var scriptItem = new FileInfo(resolvedPath);
            //    if (scriptItem.Exists)
            //        scriptItem.Delete();

            //    WriteVerbose($"ScriptPath {Path} exists");

            //    var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);
            //    var parameterService = new ParameterService(logger);
            //    var builder = new PackagePathBuilder(DropFolder, logger);
            //    var patchScriptParameterService = new PatchScriptParameterService(parameterService, builder, logger);

            //    patchScriptParameterService.WritePatchScriptParameterFile(resolvedPath, DefaultConfig, OverrideConfig, RigName, RigConfigFile);

            //    WriteObject(resolvedPath);
            //}
            //catch (Exception ex)
            //{
            //    WriteError(ex, this, ErrorCategory.ObjectNotFound, true);
            //}

            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);

            var resolvedPath = GetUnresolvedProviderPathFromPSPath(Path);

            var scriptItem = new FileInfo(resolvedPath);
            if (scriptItem.Exists)
                scriptItem.Delete();

            var baseName = System.IO.Path.GetFileNameWithoutExtension(resolvedPath);

            var parameterService = new ParameterService(logger);
            var builder = new PackagePathBuilder(DropFolder, logger);
            var patchScriptParameterService = new PatchScriptParameterService(parameterService, builder, logger);

            var targetFile = string.IsNullOrWhiteSpace(SqlScriptToRunSuffix)
                ? resolvedPath
                : System.IO.Path.Combine(scriptItem.DirectoryName, string.Concat(SqlScriptToRunSuffix, ".", baseName, scriptItem.Extension));

            patchScriptParameterService.WritePatchScriptParameterFile(targetFile, DefaultConfig, OverrideConfig, RigName, RigConfigFile);

            WriteObject(targetFile);
        }

        //protected override void WriteError<TException>(TException exception, object target, ErrorCategory category = ErrorCategory.NotSpecified, bool throwTerminating = false)
        //{
        //    var invocationInfo = GetVariableValue("MyInvocation") as InvocationInfo;

        //    if (!IsForegroundColorSet)
        //        ForegroundColor = ConsoleColor.Red;

        //    var message = BuildErrorMessage(invocationInfo, exception, "Bits", category, target);

        //    var informationMessage = new HostInformationMessage
        //    {
        //        Message = message,
        //    };

        //    try
        //    {
        //        informationMessage.ForegroundColor = ForegroundColor;
        //        informationMessage.BackgroundColor = BackgroundColor;
        //    }
        //    catch (HostException)
        //    {
        //    }

        //    var tags = new List<string> { PsHost };

        //    WriteInformation(informationMessage, tags.ToArray());
        //}
    }
}