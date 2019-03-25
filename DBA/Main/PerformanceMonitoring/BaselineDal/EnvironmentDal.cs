using System.Collections.Generic;

namespace PerformanceMonitoring.BaselineDal
{
    public class EnvironmentDal
    {
        public List<MonitoredEnvironment> MonitoredEnvironmentsGet()
        {
            Environments environments = Environments.GetSection();
            MonitoredEnvironmentCollection monitoredEnvironmentsCollection = environments.MonitoredEnvironments;
            var monitoredEnvironments = new List<MonitoredEnvironment>();

            for (int i = 0; i < monitoredEnvironmentsCollection.Count; i++)
            {
                MonitoredEnvironment environment = monitoredEnvironmentsCollection[i];
                monitoredEnvironments.Add(environment);
            }

            return monitoredEnvironments;
        }

    }
}
