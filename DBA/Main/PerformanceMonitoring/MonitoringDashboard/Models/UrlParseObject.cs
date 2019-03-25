using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;

namespace MonitoringDashboard.Models
{
    public class UrlParseObject
    {
        public UrlParseObject()
        {
            ErrorInfo = new List<string>();    
        }

        public bool IsValid { get; set; }
        public UserPreferences Preferences { get; set; }
        public List<string> ErrorInfo { get; set; }
    }
}