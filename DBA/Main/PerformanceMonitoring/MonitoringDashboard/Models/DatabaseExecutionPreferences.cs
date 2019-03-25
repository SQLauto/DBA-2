using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MonitoringDashboard.Models
{
    public class DatabaseExecutionPreferences
    {
        public string DatabaseOfInterest { get; set; }
        public string SqlOfInterest { get; set; }
        public string EnvironmentOfInterest { get; set; }
        public string StartDate { get; set; }
        public string EndDate { get; set; }
    }
}