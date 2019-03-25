using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;
using MonitoringDashboard.Models;

namespace MonitoringDashboard.Helpers
{
    public static class RadarChartBuilder
    {

        private static List<Tuple<int, int, int>> Colours;

        static RadarChartBuilder() 
        {
            Colours = new List<Tuple<int, int, int>>();
            Colours.Add(Tuple.Create(212, 212, 106));
            Colours.Add(Tuple.Create(165, 198, 99));
            Colours.Add(Tuple.Create(136, 204, 136));
            Colours.Add(Tuple.Create(212, 238, 159));
            Colours.Add(Tuple.Create(255, 255, 170));
            Colours.Add(Tuple.Create(102, 153, 153));
            Colours.Add(Tuple.Create(120, 135, 171));
            Colours.Add(Tuple.Create(146, 119, 172));
            Colours.Add(Tuple.Create(173, 116, 168));
            Colours.Add(Tuple.Create(219, 146, 175));
            Colours.Add(Tuple.Create(255, 196, 170));
        }

        public static StringBuilder BuildLegend(RadarChartSet chartSet, string title)
        {
            var builder = new StringBuilder();
            builder.AppendLine("<div class='radarLegend'>");
            builder.AppendLine(string.Format("<p>{0}</p>", title));

            for (int i = 0; i < chartSet.RadarDatasets.Count(); i++)
            {
                RadarDataset dataset = chartSet.RadarDatasets[i];
                builder.AppendFormat("<div class='radarLegendItem radarLegendItem{1}'>{0}</div>{2}", dataset.DisplayName, i, Environment.NewLine);
            }

            builder.AppendLine("</div>");

            return builder;
        }

        public static StringBuilder BuildRadarChart(RadarChartSet chartSet)
        {
            var builder = new StringBuilder();
            CreateVariablesAndLabel(builder, chartSet);

            bool isFirst = true;
            for (int i = 0; i < chartSet.RadarDatasets.Count(); i++)
            {
                if (isFirst)
                {
                    isFirst = false;
                }
                else
                {
                    builder.Append(string.Format(",{0}", Environment.NewLine));
                }
                var dataset = chartSet.RadarDatasets[i];
                CreateDataSet(dataset, builder, i);
            }

            CreateEnd(builder);

            return builder;
        }

        private static void CreateEnd(StringBuilder builder)
        {
            builder.AppendLine("]");
            builder.AppendLine("}");
            builder.AppendLine("};");
        }

        private static void CreateDataSet(RadarDataset dataset, StringBuilder builder, int ordinal)
        {
            var baseColour = GetColour(ordinal);
            var seeThroughColour = string.Format("rgba({0}, {1}, {2}, 0.2)", baseColour.Item1, baseColour.Item2, baseColour.Item3);
            var thickColour = string.Format("rgba({0}, {1}, {2}, 1)", baseColour.Item1, baseColour.Item2, baseColour.Item3);

            builder.AppendLine("{");
            builder.AppendLine(string.Format("label: {0}{1}{0},", "\"", dataset.DisplayName));
            builder.AppendLine(string.Format("backgroundColor: {0}{1}{0},", "\"", seeThroughColour));
            builder.AppendLine(string.Format("strokeColor: {0}{1}{0},", "\"", thickColour));
            builder.AppendLine(string.Format("pointBackgroundColor: {0}{1}{0},", "\"", thickColour));
            builder.AppendLine(string.Format("hoverPointBackgroundColor: {0}{1}{0},", "\"", thickColour));
            builder.AppendLine(string.Format("hoverBackgroundColor: {0}{1}{0},", "\"", thickColour));
            builder.AppendLine(string.Format("pointHighlightStroke: {0}{1}{0},", "\"", "#fff)"));
            builder.AppendLine(string.Format("pointHighlightFill: {0}{1}{0},", "\"", "#fff"));
            builder.AppendLine(string.Format("borderColor: {0}{1}{0},", "\"", thickColour));
            builder.Append("data:[");

            bool isFirst = true;
            foreach (var point in dataset.RadarPoints)
            {
                if (isFirst)
                {
                    isFirst = false;
                }
                else
                {
                    builder.Append(",");
                }
                builder.Append(point.Point);
            }

            builder.AppendFormat("]{0}", Environment.NewLine);

            builder.AppendLine("}");
        }

        private static void CreateVariablesAndLabel(StringBuilder builder, RadarChartSet chartSet)
        {
            builder.AppendLine("var config = {");
            builder.AppendLine("type: 'radar',");
            builder.AppendLine("data: {");
            builder.Append("labels: [");
            bool isFirst = true;
            foreach (var name in chartSet.RadarDatasets.First().RadarPoints.Select(x => x.Name))
            {
                if (isFirst)
                {
                    isFirst = false;
                }
                else
                {
                    builder.Append(",");
                }
                builder.AppendFormat("\"{0}\"", name);
            }
            builder.AppendFormat("],{0}", Environment.NewLine);
            builder.AppendLine("datasets:[");
        }

        private static Tuple<int, int, int> GetColour(int ordinal)
        {
            return Colours[ordinal];
        }
    }
}