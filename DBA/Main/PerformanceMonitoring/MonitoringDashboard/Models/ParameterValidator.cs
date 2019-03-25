using System;
using System.Linq;

namespace MonitoringDashboard.Models
{
    public class ParameterValidator
    {
        public static bool ParseDate(string dateTime1, string dateTime2)
        {
            DateTime firstDateTime;
            DateTime secondDateTime;
            var result1 = 0;
            var result2 = 0;
     
            if (!DateTime.TryParse(dateTime1, out firstDateTime))
            {
                result1++;
            }            
            if (!DateTime.TryParse(dateTime2, out secondDateTime))
            {
                result2++;
            }
            if (result1 != 0 || result2 != 0)
            {
                return false;
            }
            return true;                          
        }

        public static bool ParseEnvironment(string environment)
        {            
            string[] environmentsArray = {"Devint", "PreProd", "Pre-Prod"};
            if (!environmentsArray.Contains(environment))
            {
                return false;
            }                                        
            return true;
        }

        public static bool ParseDatabase(string environment ,string database)
        {           
            var result1 = 0;
            var result2 = 0;
            string[] devintDbArray = {"FAE", "Pare","PARE", "Other"};
            string[] preProdDbArray = {"FAE","Pare","PARE"};
            if (environment == "Devint" && !devintDbArray.Contains(database))
            {
                result1++;
            }
            if (environment == "PreProd" && !preProdDbArray.Contains(database))
            {
                result2++;
            }
            if (result1 != 0 || result2 != 0)
            {
                return false;
            }
            return true;
        }

        public static bool ParseTitle(string title)
        {
            string[] titles =
            {
                "Total IOPs", "Total Num. Execs", "Total Worker Time Seconds", "Total Physical Reads", "Total Logical Writes",
                "Total Logical Reads", "Total Elapsed Time (s)", "Longest Running Time (s)", "Avg. IOPs per call", "Avg. Elapsed Time (ms)",
                "Avg. Num. Execs per Sproc", "Avg IOPs per sproc"
            };
            if (!titles.Contains(title))
            {
                return false;
            }
            return true;
        }

        public static bool ParseValue(string value)
        {
            //Add condition for value to check against what the actual value is. 
            decimal number;
            bool result = decimal.TryParse(value, out number);
            if (!result || number > 100 || number < 0)
            {
                return false;
            }
            return true;
        }

        public static bool ParseSqlOfInterest(string sqlOfInterest)
        {
            string[] sqlStrings =
            {
                "OceanBoiling Iops", "Mega Iops", "Godzilla Iops", "I am Here Iops", "Same Value Iops", "Moderate Iops",
                "Low Iops", "Are you there IOPS"
            };
            if (!sqlStrings.Contains(sqlOfInterest))
            {
                return false;
            }
            return true;
        }
    }
}