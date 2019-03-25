using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MonitoringDashboard.Models
{
    public class BarChartPreferences
    {
        public UserPreferences Preferences { get; set; }
        public string DatabaseOfInterest { get; set; }
        public string Title { get; set; }
        public decimal Value { get; set; }
        public bool IsEnvironment1 { get; set; }
    }
}