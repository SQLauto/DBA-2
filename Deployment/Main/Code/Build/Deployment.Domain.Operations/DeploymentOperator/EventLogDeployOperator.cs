using System.Collections.Generic;
using System.Diagnostics;
using Deployment.Common.Logging;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Roles;
using System;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class EventLogDeployOperator : IDeploymentOperator<EventLogDeploy>
    {
        private readonly IDeploymentLogger _logger;
        private readonly IParameterService _parameterService;


        public EventLogDeployOperator(IParameterService parameterService = null, IDeploymentLogger logger = null)
        {
            _parameterService = parameterService ?? new ParameterService(logger);
            _logger = logger;
        }

        public bool PreDeploymentValidate(EventLogDeploy role, ConfigurationParameters parameters, List<string> outputLocations) => true;

        public IList<ArchiveEntry> GetDeploymentFiles(EventLogDeploy role, List<string> dropFolders, ConfigurationParameters parameters) => null;

        public bool PostDeploymentValidate(PostDeployParameters postDeployParameters, EventLogDeploy role)
        {
            if (role.DisablePostDeploymentTests)
            {
                return true;
            }

            var exists = EventLog.Exists(role.EventLogName, postDeployParameters.Machine.ExternalIpAddress);

            return role.Action == EventLogAction.Install ? exists : !exists;
        }
    }
}