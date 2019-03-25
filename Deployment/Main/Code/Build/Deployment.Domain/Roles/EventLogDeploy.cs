using System;
using System.Collections.Generic;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class EventLogDeploy : BaseRole, IDeploymentRole, IPostDeploymentRole
    {
        public EventLogDeploy(string configuration)
        {
            Sources = new List<string>();
            Action = EventLogAction.Install;
            MaxLogSizeInKiloBytes = 1024;
            Configuration = configuration;
            RoleType = "EventLog Deploy";
        }
        public IList<string> Sources { get; set; }
        [Mandatory]
        public string EventLogName { get; set; }
        public int MaxLogSizeInKiloBytes { get; set; }
        public bool DisablePostDeploymentTests { get; set; }
        public EventLogAction Action { get; set; }
    }

    public enum EventLogAction
    {
        Install = 0,
        Uninstall
    }
}