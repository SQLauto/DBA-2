using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using Dto;
using MonitoringService;

namespace ConsoleApplication
{
    class Program
    {
        static void Main(string[] args)
        {
           // var x = EnvironmentDefinitionsDal.SettingsGet();
           // Environments environments = Environments.GetSection();
            //EnvironmentsService service = new EnvironmentsService();
            //List<MonitoredEnvironment> monitoredEnvironments = service.EnvironmentsGet();

            var dto = new ReportParametersDto
            {
                DatabaseName = "FAE",
                StartDate = DateTime.Now.AddMonths(-3),
                EndDate = DateTime.Now.AddMonths(-2),
                Enviroment = "devint"
            };

            var reportService = new ReportService();
            var x = reportService.AverageElapsedTimeGet(dto);

            Console.Read();
        }
    }
}
