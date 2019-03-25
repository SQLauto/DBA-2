using System.Collections.Generic;
using System.Linq;
using Deployment.Common;

namespace Deployment.Tool.Tasks
{
    public class DeploymentToolsTasksList<T> where T: IDeploymentToolTask
    {
        private List<T> Tasks { get; set; }

        public DeploymentToolsTasksList()
        {
            Tasks = new List<T>();
        }

        public void Add(T task)
        {
            Tasks.Add(task);
        }

        public Dictionary<string, IDeploymentToolTask> GetTaskDictionary()
        {
            return Tasks.ToDictionary<T, string, IDeploymentToolTask>(task => task.TaskType.Description(), task => task);
        }

    }
}