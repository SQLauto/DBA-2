using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Web;
using Dto;

namespace MonitoringDashboard.Helpers
{
    public class BarChartBuilder
    {
        private static string DateTimeFormat = "dd MMM yyyy hh:mm";

        public static StringBuilder BuildBarChart(DatabaseScalarMetricSet metricSet)
        {
            var builder = new StringBuilder();
            CreateBarChartDataSets(metricSet, builder);

            return builder;
        }

        private static void CreateBarChartDataSets(DatabaseScalarMetricSet metricSet, StringBuilder builder)
        {
            var scalars = metricSet.Scalars.OrderByDescending(x => x.Value).ToList();
            builder.AppendLine("var barChartData = {");
            CreateLabels(builder, scalars);
            builder.Append("datasets: [{");
            builder.AppendLine();
            string title = metricSet.MetricName;
            builder.AppendFormat("label: '{0}',", title);
            builder.AppendLine("backgroundColor: 'rgba(220,220,220,0.5)',");
            CreateDataValues(scalars, builder);
            builder.AppendLine("}]");
            builder.AppendLine("};");
        }

        private static void CreateDataValues(List<DatabaseScalarValue> scalars, StringBuilder builder)
        {
            builder.Append("data: [");
            bool isFirst = true;
            foreach (var scalar in scalars)
            {
                if (!isFirst)
                {
                    builder.Append(",");
                }
                else
                {
                    isFirst = false;
                }

                builder.Append(scalar.Value);
            }

            builder.AppendFormat("],{0}", Environment.NewLine);
        }

        private static void CreateLabels(StringBuilder builder, List<DatabaseScalarValue> scalars)
        {
            builder.Append("labels: [");
            bool isFirst = true;
            foreach (var scalar in scalars)
            {
                if (!isFirst)
                {
                    builder.Append(",");
                }
                else
                {
                    isFirst = false;
                }

                builder.AppendFormat("'{0}'", scalar.Name);
            }

            builder.AppendFormat("],{0}", Environment.NewLine);
        }

        private static string GenerateTitle(DatabaseScalarMetricSet metricSet)
        {
            string title = string.Format("In: [{0}] for: [{1}] of metric: [{4}] from: [{2}] to: [{3}]", metricSet.EnvironmentName, metricSet.DatabaseName, 
                metricSet.Start.ToString(DateTimeFormat), metricSet.End.ToString(DateTimeFormat), metricSet.MetricName);

            return title;
        }
    }
}