using System;

namespace Dto
{
    public class ReportParametersDto
    {
        public string Enviroment { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string DatabaseName { get; set; }
    }
}