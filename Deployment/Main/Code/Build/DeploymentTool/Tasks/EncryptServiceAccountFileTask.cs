using Deployment.Common;
using Deployment.Common.Logging;
using Deployment.Domain.Operations;

namespace Deployment.Tool.Tasks
{
    public class EncryptServiceAccountFileTask : IDeploymentToolTask
    {
        private readonly IDeploymentLogger _logger = new ConsoleLogger();

        public EncryptServiceAccountFileTask()
        {

        }

        public DeploymentTaskType TaskType => DeploymentTaskType.Encrypt;

        public bool ValidateInputParameters(DeploymentOperationParameters toolParameters)
        {
            if (string.IsNullOrEmpty(toolParameters.ServiceAccountsFile) || string.IsNullOrEmpty(toolParameters.Password))
            {
                _logger?.WriteWarn("Must supply a valid service accounts file name and password for encryption");
                return false;
            }

            return true;
        }

        public bool TaskWork(DeploymentOperationParameters toolParameters)
        {
            var manager = new ServiceAccountsManager(toolParameters.Password, _logger);
            var success = manager.EncryptServiceAccountFile(toolParameters.ServiceAccountsFile, toolParameters.ServiceAccountsFile);

            if (!success)
                _logger?.WriteError("Failed to encrypt service account file.");

            return success;
        }
    }
}