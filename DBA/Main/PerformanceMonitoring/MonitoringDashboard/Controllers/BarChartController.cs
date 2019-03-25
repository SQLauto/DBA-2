using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Dto;
using MonitoringDashboard.Helpers;
using MonitoringDashboard.Models;
using MonitoringService;

namespace MonitoringDashboard.Controllers
{
    public class BarChartController : Controller
    {
        private static readonly Dictionary<string, BarChartScalarType> ChartTypes = new Dictionary<string, BarChartScalarType>();

        static BarChartController()
        {
            ChartTypes.Add("Total IOPs", BarChartScalarType.TotalIops);
            ChartTypes.Add("Total Num. Execs", BarChartScalarType.TotalNumberOfExecutions);
            ChartTypes.Add("Total Worker Time Seconds", BarChartScalarType.TotalWorkerTimeSeconds);
            ChartTypes.Add("Total Physical Reads", BarChartScalarType.TotalPhysicalReads);
            ChartTypes.Add("Total Logical Writes", BarChartScalarType.TotalLogicalReads);
            ChartTypes.Add("Total Elapsed Time (s)", BarChartScalarType.TotalElapsedTimeSeconds);
            ChartTypes.Add("Longest Running Time (s)", BarChartScalarType.LongestRunningTimeSeconds);
            ChartTypes.Add("Avg. IOPs per call", BarChartScalarType.AverageIopsPerCall);
            ChartTypes.Add("Avg. Elapsed Time (ms)", BarChartScalarType.AverageElapsedTimeMilliSeconds);
            ChartTypes.Add("Avg. Num. Execs per Sproc", BarChartScalarType.AverageNumberExecutionsPerSproc);
            ChartTypes.Add("Avg IOPS per sproc", BarChartScalarType.AverageIopsPerSproc);
        }

        public ActionResult Index(string environment, string startDate, string endDate, string databaseOfInterest, string title, string value)
        {
            List<string> modelError = new List<string>();
            var service = new BaselineService();
            //TODO How to deal with spaces in incorrect places          
            if (!ParameterValidator.ParseEnvironment(environment))
            {
                modelError.Add("There is a problem with the environment\n");
            }
            if (!ParameterValidator.ParseDate(startDate, endDate))
            {
                modelError.Add("There is a problem with the dates\n");
            }
            if (!ParameterValidator.ParseDatabase(environment, databaseOfInterest))
            {
                modelError.Add("There is a problem with the database");
            }
            if (!ParameterValidator.ParseTitle(title))
            {
                modelError.Add("There is a problem with the entered title");
            }
            //TODO Stop user from typing in wrong value
            if (!ParameterValidator.ParseValue(value))
            {
                modelError.Add("There is a problem with the passed in value");
            }
            if (!ChartTypes.ContainsKey(title))
            {
                modelError.Add("The type of bar chart being requested is unknown.");
            }

            if (modelError.Any())
            {
                return View("BarChartError", modelError);
            }
                
            DateTime start = DateTime.Parse(startDate);
            DateTime end = DateTime.Parse(endDate);

            

            BarChartScalarType typeOfBarChartToCreate = ChartTypes[title];
            DatabaseScalarMetricSet model = service.DatabaseScalarMetricsGet(environment, start, end, databaseOfInterest,
                value, typeOfBarChartToCreate);
            model.MetricName = title;
                
            return View(model);            
        }

        public ActionResult GetExecutionDetailsRedirect(DatabaseExecutionPreferences executionPreferences)
        {
            string barChartUrl = UrlBuilder.ExecutionDetailsUrl(executionPreferences, Url);
            var reference = new UrlReference
            {
                ErrorMessage = "An error occured",
                IsValid = true,
                Url = barChartUrl
            };
            var result = Json(reference);
            return result;
        }
    }
}