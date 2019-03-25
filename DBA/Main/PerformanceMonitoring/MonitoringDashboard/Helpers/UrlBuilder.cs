using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Security.Policy;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;
using Dto;
using MonitoringDashboard.Models;

namespace MonitoringDashboard.Helpers
{
    public static class UrlBuilder
    {

        private const string DateTimeFormat = "yyyy/MM/dd hh:mm";

        public static List<Parameter> UserPreferencesToParameters(UserPreferences preferences)
        {
            Parameter criteria1Parameter = CreateCriteriaHttpRequestParameters(preferences.Criteria1, "criteria1");
            var parameters = new List<Parameter> {criteria1Parameter};

            string criteria2Name = "criteria2";
            if (preferences.Criteria2 != null)
            {
                Parameter criteria2Parameter = CreateCriteriaHttpRequestParameters(preferences.Criteria2, criteria2Name);
                parameters.Add(criteria2Parameter);
            }
            else
            {
                parameters.Add(new Parameter{Name = criteria2Name, Value = string.Empty});
            }

            return parameters;
        }

        private static Parameter CreateCriteriaHttpRequestParameters(EnvironmentCriteria criteria, string parameterName)
        {
            var parameter = new Parameter {Name = parameterName};

            if (criteria.EnvironmentName == "none")
            {
                parameter.Value = "null";
                return parameter;
            }

            var builder = new StringBuilder();
            builder.AppendFormat("{0}=", parameterName);
            builder.AppendFormat("EnvName({0})~", criteria.EnvironmentName);
            builder.AppendFormat("Start1({0})~", criteria.Start.ToString(DateTimeFormat));
            builder.AppendFormat("End1({0})~", criteria.End.ToString(DateTimeFormat));

            for(int i = 0; i < criteria.DatabasesOfInterest.Count; i++)
            {
                string database = criteria.DatabasesOfInterest[i];
                builder.AppendFormat("Database({0})", database);
                if (i != (criteria.DatabasesOfInterest.Count - 1))
                {
                    builder.Append("~");
                }
            }
           
            parameter.Value = builder.ToString();
            return parameter;
        }

        //to do make this robust
        public static UrlParseObject ParseParameters(string criteria1, string criteria2)
        {
            var parseObject = new UrlParseObject();
            var preferences = parseObject.Preferences = new UserPreferences();

            if (string.IsNullOrWhiteSpace(criteria1))
            {
                parseObject.ErrorInfo.Add("Criteria 1 MUST be specified.");
                return parseObject;
            }

            preferences.Criteria1 = CreateCriterion(criteria1, parseObject);

            if (!string.IsNullOrWhiteSpace(criteria2))
            {
                preferences.Criteria2 = CreateCriterion(criteria2, parseObject);
            }

            return parseObject;
        }

        private static EnvironmentCriteria CreateCriterion(string criteria, UrlParseObject parseObject)
        {
            if (criteria == "null")
            {
                return null;
            }

            criteria = criteria.Replace("criteria1=", string.Empty);
            criteria =  criteria.Replace("criteria2=", string.Empty);

            var criterion = new EnvironmentCriteria();
            bool parsed;
            DateTime dateTimeParsed;
            string[] parameters  = criteria.Split(new []{"~"}, StringSplitOptions.RemoveEmptyEntries);
            foreach (var parameter in parameters)
            {
                Parameter param = ExtractParameter(parameter);
                switch (param.Name)
                {
                    case "EnvName":
                        criterion.EnvironmentName = param.Value;
                        break;
                    case "Start1":
                        parsed = DateTime.TryParseExact(param.Value, DateTimeFormat, CultureInfo.InvariantCulture, DateTimeStyles.None, out dateTimeParsed);
                        if (parsed)
                        {
                            criterion.Start = dateTimeParsed;
                        }
                        break;
                    case "End1":
                        parsed = DateTime.TryParseExact(param.Value, DateTimeFormat, CultureInfo.InvariantCulture, DateTimeStyles.None, out dateTimeParsed);
                        if (parsed)
                        {
                            criterion.End = dateTimeParsed;
                        }
                        break;
                    case "Database":
                        criterion.DatabasesOfInterest.Add(param.Value);
                        break;
                }
            }

            return criterion;
        }

        private static Parameter ExtractParameter(string parameter)
        {
            int open = parameter.IndexOf('(');
            int close = parameter.IndexOf(')');

            var p = new Parameter();
            p.Name = parameter.Substring(0, open);
            p.Value = parameter.Substring(open + 1, (close - open) -1);

            return p;
        }

        public static string RadarChartUrl(UserPreferences preferences, UrlHelper url)
        {
            RouteValueDictionary values = GetUserParameters(preferences);

            var radarChartUrl = url.Action("Index", "Radar", values);//, "http", "localhost");

            return radarChartUrl;
        }

        private static RouteValueDictionary GetUserParameters(UserPreferences preferences)
        {
            List<Parameter> parameters = UserPreferencesToParameters(preferences);
            RouteValueDictionary values = new RouteValueDictionary();
            foreach (var parameter in parameters)
            {
                values.Add(parameter.Name, parameter.Value);
            }
            return values;
        }

        public static string BarChartUrl(BarChartPreferences barChartPreferences, UrlHelper url)
        {
            var critria = barChartPreferences.IsEnvironment1 ? barChartPreferences.Preferences.Criteria1 : barChartPreferences.Preferences.Criteria2;
            
            var values = new RouteValueDictionary();
            values.Add("environment", critria.EnvironmentName);
            values.Add("startDate", critria.Start.ToString(DateTimeFormat));
            values.Add("endDate", critria.End.ToString(DateTimeFormat));
            values.Add("databaseOfInterest", barChartPreferences.DatabaseOfInterest.Replace("~", string.Empty));
            values.Add("title", barChartPreferences.Title);
            values.Add("value", barChartPreferences.Value);
            
            var barChartUrl = url.Action("Index", "BarChart", values);
            return barChartUrl;
        }

        public static string ExecutionDetailsUrl(DatabaseExecutionPreferences dbExecutionPreferences, UrlHelper url)
        {
            var values = new RouteValueDictionary();
            values.Add("environment", dbExecutionPreferences.EnvironmentOfInterest);
            values.Add("startDate", dbExecutionPreferences.StartDate);
            values.Add("endDate", dbExecutionPreferences.EndDate);
            values.Add("databaseOfInterest", dbExecutionPreferences.DatabaseOfInterest.Replace("~", string.Empty));
            values.Add("sqlOfInterest", dbExecutionPreferences.SqlOfInterest);

            var executionDetailsUrl = url.Action("Index", "DatabaseExecution", values);

            return executionDetailsUrl;
        }

        public static string GetViewExecutionPlan(string environment, DateTime startDate, DateTime endDate, string databaseOfInterest, string sqlOfInterest, UrlHelper url)
        {
            var values = new RouteValueDictionary();
            values.Add("environment", environment);
            values.Add("startDate", startDate.ToString(DateTimeFormat));
            values.Add("endDate", endDate.ToString(DateTimeFormat));
            values.Add("databaseOfInterest", databaseOfInterest.Replace("~", string.Empty));
            values.Add("sqlOfInterest", sqlOfInterest);

            var executionDetailsUrl = url.Action("GetExecutionPlan", "DatabaseExecution", values);

            return executionDetailsUrl;
        }
    }

    public class Parameter
    {
        public string Name { get; set; }
        public string Value { get; set; }
    }

}