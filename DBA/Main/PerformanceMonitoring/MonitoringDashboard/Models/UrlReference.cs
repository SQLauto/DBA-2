using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MonitoringDashboard.Models
{
    public class UrlReference
    {
        public string Url { get; set; }
        public bool IsValid { get; set; }
        public string ErrorMessage { get; set; }
    }
}