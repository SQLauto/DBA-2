using System.Collections.Generic;
using PerformanceMonitoring.BaselineDal;
using MonitoredEnvironment = Dto.MonitoredEnvironment;

namespace MonitoringService
{
    public class EnvironmentsService
    {
        public List<MonitoredEnvironment> EnvironmentsGet()
        {
            var dal = new EnvironmentDal();

            var environments = dal.MonitoredEnvironmentsGet();
            var monitoredEnvironments = new List<MonitoredEnvironment>();

            foreach (PerformanceMonitoring.BaselineDal.MonitoredEnvironment environment in environments)
            {
                var monitoredEnvironment = new MonitoredEnvironment();
                monitoredEnvironment.EnvironmentName = environment.EnvironmentName;

                for (int i = 0; i < environment.Count; i++)
                {
                    MonitoredDatabase database = environment[i];
                    monitoredEnvironment.Databases.Add(database.DatabaseName);
                }

                monitoredEnvironments.Add(monitoredEnvironment);
            }

            return monitoredEnvironments;

            return new List<MonitoredEnvironment>
            {
                new MonitoredEnvironment
                {
                    EnvironmentName = "Pre-Prod",
                    Databases = new List<string>
                    {
                        "Fae",
                        "Pare",
                        "ReportingRw"
                    }
                },
                new MonitoredEnvironment
                {
                    EnvironmentName = "Devint",
                    Databases = new List<string>
                    {
                        "Fae",
                        "Pare",
                        "ReportingRw",
                        "ANother"
                    }
                }
            };
        }
    }
}
