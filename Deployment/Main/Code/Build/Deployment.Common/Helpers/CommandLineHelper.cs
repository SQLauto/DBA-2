using System;
using System.Diagnostics;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Security;
using System.Text.RegularExpressions;
using Deployment.Common.Logging;

namespace Deployment.Common.Helpers
{
    public class CommandLineHelper : ICommandLineHelper
    {
        private readonly IDeploymentLogger _logger;
        public CommandLineHelper(IDeploymentLogger logger)
        {
            _logger = logger;
        }

        public string GetCommandLineParameter(string commandLine, string parameterName)
        {
            int index = commandLine.IndexOf(parameterName, StringComparison.OrdinalIgnoreCase);
            if (index == -1)
            {
                return string.Empty;
            }

            var parameterValue = commandLine.Substring(index + parameterName.Length).Trim();

            parameterValue = parameterValue.TrimStart('\'');
            if (parameterValue.IndexOf('\'') > -1)
            {
                parameterValue = parameterValue.Substring(0, parameterValue.IndexOf('\''));
            }

            return parameterValue;
        }

        public string GetCommandLineParameterPathWithoutTrailingSlash(string commandLine, string parameterName)
        {
            var paramValue = GetCommandLineParameter(commandLine, parameterName);
            if (paramValue.EndsWith(@"\"))
            {
                paramValue = paramValue.Substring(0, paramValue.Length - 1);
            }

            return paramValue;
        }

        public int PowershellCommand(string cmdArgs)
        {
            int exitCode;
            using (var process = new Process())
            {
                process.StartInfo = new ProcessStartInfo
                {
                    WindowStyle = ProcessWindowStyle.Hidden,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    FileName = "powershell.exe",
                    Verb = "runas",
                    Arguments = cmdArgs
                };

                process.Start();
                process.WaitForExit();
                exitCode = process.ExitCode;
            }

            return exitCode;
        }

        public int RemotePowershellCommand(string remoteMachine, string cmdArgs, string userName, string password)
        {
            int exitCode = 1;
            string shellUri = "http://schemas.microsoft.com/powershell/Microsoft.PowerShell";

            SecureString securePassword = new SecureString();
            foreach(char c in password.ToCharArray()) { securePassword.AppendChar(c); }
            PSCredential credential = new PSCredential(userName, securePassword);
            WSManConnectionInfo connectionInfo = new WSManConnectionInfo(false, remoteMachine, 5985, "/wsman", shellUri, credential);
            connectionInfo.AuthenticationMechanism = AuthenticationMechanism.Credssp;
            _logger?.WriteLine($"Executing Remote Powershell with command: { cmdArgs }");

            using (Runspace runspace = RunspaceFactory.CreateRunspace(connectionInfo))
            {
                runspace.Open();
                Pipeline pipeline = runspace.CreatePipeline(cmdArgs);
                var output = pipeline.Invoke();
                if(!pipeline.HadErrors)
                    exitCode = 0;
            }            

            return exitCode;
        }

        public int PsExecCommand(string remoteMachine, string cmdArgs, string userName, string password)
        {
            int exitCode;
            string output;
            using (var process = new Process())
            {
                process.StartInfo = new ProcessStartInfo
                {
                    WindowStyle = ProcessWindowStyle.Hidden,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    FileName = "PsExec.exe",
                    Verb = "RunAs",
                    RedirectStandardOutput = true,
                    Arguments = $@"/accepteula \\{remoteMachine} -h -nobanner "
                };

                if (!string.IsNullOrEmpty(userName) && !string.IsNullOrEmpty(password))
                {
                    process.StartInfo.Arguments += $"-u \"{userName}\" ";
                    process.StartInfo.Arguments += $"-p \"{password}\" ";
                }

                process.StartInfo.Arguments += cmdArgs;

                _logger?.WriteLine($"Executing PsExec using arguments: { process.StartInfo.Arguments}");

                process.Start();
                output = process.StandardOutput.ReadToEnd();
                process.WaitForExit();
                exitCode = process.ExitCode;
            }

            var lines = Regex.Split(output, @"\n");

            foreach (var line in lines)
            {
                _logger?.WriteLine(line.Replace(@"{", @"{{").Replace(@"}", @"}}"));
            }

            return exitCode;
        }
    }
}