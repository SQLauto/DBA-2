using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using MonitoringDashboard.Helpers;
using MonitoringDashboard.Models;

namespace MonitoringDashboard.Controllers
{
    public class HomeController : Controller
    {
        //
        // GET: /Home/

        public ActionResult Index()
        {
            return View();
        }


        [HttpPost]
        public ActionResult GetRadarRedirect(UserPreferences userPreference)
        {
            Session[SessionVariables.UserPreferences.ToString()] = userPreference;
            string radarChartUrl = UrlBuilder.RadarChartUrl(userPreference, Url);
            var reference = new UrlReference
            {
                ErrorMessage = "An error occured",
                IsValid = true,
                Url = radarChartUrl
            };

            
            var result = Json(reference);
            return result;
        }


    }
}
