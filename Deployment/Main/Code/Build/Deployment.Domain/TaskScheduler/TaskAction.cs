using System;
using Deployment.Domain.Roles;

namespace Deployment.Domain.TaskScheduler
{
    [Serializable]
    public class TaskAction
    {
        public string Command { get; set; }
        public string Arguments { get; set; }
        public string StartIn { get; set; }
        public ActionType ActionType { get; set; }
        public string MessageTitle { get; set; }
        public string Message { get; set; }
        //TODO: Finish off properties for Email type if ever required.

    }
}