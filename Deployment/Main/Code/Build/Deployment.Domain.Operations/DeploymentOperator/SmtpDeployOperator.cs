using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Sockets;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class SmtpDeployOperator : IDeploymentOperator<SmtpDeploy>
    {
        private readonly IDeploymentLogger _logger;

        public SmtpDeployOperator(IParameterService parameterService = null, IDeploymentLogger logger = null)
        {
            _logger = logger;
        }

        public bool PreDeploymentValidate(SmtpDeploy role, ConfigurationParameters parameters, List<string> outputLocations)
        {
            bool isValid = true;
            var foundIpRelayFile = false;

            foreach (string location in outputLocations)
            {
                string relayIpFileLocation = Path.Combine(location, role.FileLocation, role.RelayIpFile);
                if (File.Exists(relayIpFileLocation))
                {
                    foundIpRelayFile = true;
                    break;
                }
            }

            if(!foundIpRelayFile)
            {
                isValid = false;
                _logger?.WriteWarn($"Relay Ip file '{role.RelayIpFile}' cannot be found");
            }
            return isValid;
        }

        public IList<ArchiveEntry> GetDeploymentFiles(SmtpDeploy role, List<string> dropFolders, ConfigurationParameters parameters)
        {
            var files = new List<ArchiveEntry>();

            // The ip relay file
            foreach (var dropFolder in dropFolders)
            {
                string relayIpFile = Path.Combine(dropFolder, role.FileLocation, role.RelayIpFile);

                if (File.Exists(relayIpFile))
                {
                    files.Add(new ArchiveEntry
                    {
                        FileLocation = relayIpFile,
                        FileRelativePath = FileHelper.GetFileRelativePath(relayIpFile, dropFolder),
                        FileName = string.Empty
                    });
                    break;
                }
            }

            return files;
        }

        public bool PostDeploymentValidate(PostDeployParameters postDeployParameters, SmtpDeploy role)
        {
            bool result = true;
            using (var timer = new PerformanceLogger(_logger))
            {
                try
                {
                    var tcp = new TcpClient();
                    tcp.Connect(postDeployParameters.Machine.DeploymentAddress, 25);
                    timer.WriteSummary(
                        $"SMTP service is available on '{postDeployParameters.Machine.DeploymentAddress}'.", LogResult.Success);
                }
                catch (Exception ex)
                {
                    timer.WriteSummary(
                        $"SMTP service is not available '{postDeployParameters.Machine.DeploymentAddress}'.", LogResult.Fail);
                    _logger?.WriteError(ex);
                    result = false;
                }
            }

            return result;
        }
    }
}