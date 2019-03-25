using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Mime;
using System.Web;
using System.Web.Mvc;
using Dto;
using MonitoringDashboard.Models;
using MonitoringService;

namespace MonitoringDashboard.Controllers
{
    public class DatabaseExecutionController : Controller
    {
        public ActionResult Index(string environment, string startDate, string endDate, string databaseOfInterest, string sqlOfInterest)
        {
            //TODO How to deal with spaces in incorrect places
            List<string> errors = new List<string>();
            var service = new BaselineService();
            if (!ParameterValidator.ParseDate(startDate,endDate))
            {
               errors.Add("There is a problem with the dates");
            }
            if (!ParameterValidator.ParseEnvironment(environment))
            {
                errors.Add("There is a problem with the environment");
            }
            if (!ParameterValidator.ParseDatabase(environment,databaseOfInterest))
            {
                errors.Add("There is a problem with the database");
            }
            if (!ParameterValidator.ParseSqlOfInterest(sqlOfInterest))
            {
                errors.Add("There was a problem receiving the sqlOfInterest");
            }
            if (errors.Any())
            {
                return View("DatabaseExecutionError", errors);
            }
            
             var model = service.DatabaseExecutionMetricGet(environment, startDate, endDate, databaseOfInterest,
                sqlOfInterest);
               return View(model); 
        }

        public FileStreamResult GetExecutionPlan(string environment, string startDate, string endDate, string databaseOfInterest, string sqlOfInterest)
        {
            var service = new BaselineService();
            var model = service.DatabaseExecutionMetricGet(environment, startDate, endDate, databaseOfInterest,
                sqlOfInterest);

            Stream stream = ToStream(model.LatestExecutionPlan);
            return File(stream, "application/sql", "ExecutionPlan.sqlplan");
        }

        public static Stream ToStream(string str)
        {
            var stream = new MemoryStream();
            var writer = new StreamWriter(stream);
            writer.Write(str);
            writer.Flush();
            stream.Position = 0;
            return stream;
        }
    }
}
