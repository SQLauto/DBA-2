using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Dto;
using MonitoringDashboard.Helpers;
using MonitoringDashboard.Models;
using MonitoringService;

namespace MonitoringDashboard.Controllers
{
    public class RadarController : Controller
    {
        //
        // GET: /Radar/

        public ActionResult Index(string criteria1, string criteria2)
        {
            //parse criteria
            //Split strings to get value from criteria
            //TODO How to deal with spaces in incorrect places
            List<string> errors = new List<string>();
            string environmentSplit = criteria1.Split('(', ')')[1];
            string firstDateSplit = criteria1.Split('(', ')')[3];
            string endDateSplit = criteria1.Split('(', ')')[5];
            string dbSplit = criteria1.Split('(', ')')[7];
            UrlParseObject parseObject = UrlBuilder.ParseParameters(criteria1, criteria2);
                     
                if (!parseObject.IsValid)
                {
                    if (!ParameterValidator.ParseEnvironment(environmentSplit))
                    {
                        errors.Add("There is a problem with the environment");
                    }
                    if (!ParameterValidator.ParseDate(firstDateSplit,endDateSplit))
                    {
                        errors.Add("There is a problem with the dates");
                    }
                    if (!ParameterValidator.ParseDatabase(environmentSplit,dbSplit))
                    {
                        errors.Add("There is a problem with the database");
                    }
                    if (errors.Any())
                    {                       
                    return View("RadarError",errors); 
                    }                   
                }   
            
            //Generate data.
            var baselineService = new BaselineService();

            DatabaseMacroMetricSetNormalised dataset = baselineService.DatabaseMacroMetricNormalisedSetGet(parseObject.Preferences.Criteria1,
                parseObject.Preferences.Criteria2);

            return View(dataset);
        }

        public ActionResult GetScalarMetricRedirect(BarChartPreferences  barChartPreferences)
        {
            UserPreferences userPreference = barChartPreferences.Preferences;
            Session[SessionVariables.UserPreferences.ToString()] = userPreference;
            string barChartUrl = UrlBuilder.BarChartUrl(barChartPreferences, Url);
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
