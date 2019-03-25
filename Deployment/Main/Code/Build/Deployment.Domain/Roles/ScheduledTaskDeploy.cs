using System;
using System.Collections.Generic;
using Deployment.Common;
using Deployment.Domain.TaskScheduler;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class ScheduledTaskDeploy : BaseRole, IDeploymentRole
    {
        public ScheduledTaskDeploy(string configuration)
        {
            Configuration = configuration;
            Triggers = new List<ScheduleInfo>();
            Actions = new List<TaskAction>();
            Folder = "FTP";
            RoleType = "Scheduled Task Deploy";
            Account = new ServiceAccount();
        }

        [Mandatory]
        public string TaskName { get; set; }
        public string Folder { get; set; }
        [Mandatory]
        public ServiceAccount Account { get; set; }
        public string TaskDescription { get; set; }
        public bool Enabled { get; set; }
        [Mandatory]
        public IList<ScheduleInfo> Triggers { get; set; }
        [Mandatory]
        public IList<TaskAction> Actions { get; set; }
        public ScheduledTaskAction Action { get; set; }
        public bool DisableTests { get; set; }
    }


}