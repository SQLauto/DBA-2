using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using Dto;
using PerformanceMonitoring.BaselineDal.Properties;

namespace PerformanceMonitoring.BaselineDal
{
    public class ReportDal
    {
        public List<DatabaseScalarValue> AverageElapsedTimeGet(ReportParametersDto paramDto)
        {
            const string procName = "report.AverageElapsedTimeGet";
            const string columnName = "AverageElapsedTimeMilliSeconds";
            var scalars = GetScalars(paramDto, procName, columnName);

            return scalars;
        }

        public List<DatabaseScalarValue> AverageIopsPerCallGet(ReportParametersDto paramDto)
        {
            const string procName = "report.AverageIopsPerCallGet";
            const string columnName = "AverageIopsPerCall";
            var scalars = GetScalars(paramDto, procName, columnName);

            return scalars;
        }

        public List<DatabaseScalarValue> LongestRunningQueriesGet(ReportParametersDto paramDto)
        {
            const string procName = "report.LongestRunningTimeGet";
            const string columnName = "LongestRunningTimeSeconds";
            var scalars = GetScalars(paramDto, procName, columnName);

            return scalars;
        }

        public List<DatabaseScalarValue> TotalElapsedTimeGet(ReportParametersDto paramDto)
        {
            const string procName = "report.TotalElapsedTimeGet";
            const string columnName = "TotalElapsedTimeSeconds";
            var scalars = GetScalars(paramDto, procName, columnName);

            return scalars;
        }

        public List<DatabaseScalarValue> TotalIopsGet(ReportParametersDto paramDto)
        {
            const string procName = "report.TotalIopsGet";
            const string columnName = "TotalIops";
            var scalars = GetScalars(paramDto, procName, columnName);

            return scalars;
        }

        public List<DatabaseScalarValue> TotalLogicalReadsGet(ReportParametersDto paramDto)
        {
            const string procName = "report.TotalLogicalReadsGet";
            const string columnName = "TotalLogicalReads";
            var scalars = GetScalars(paramDto, procName, columnName);

            return scalars;
        }

        public List<DatabaseScalarValue> TotalNumberOfExecutionsGet(ReportParametersDto paramDto)
        {
            const string procName = "report.TotalNumberOfExecutionsGet";
            const string columnName = "TotalNumberExecutions";
            var scalars = GetScalars(paramDto, procName, columnName);

            return scalars;
        }

        public List<DatabaseScalarValue> TotalPhysicalReadsGet(ReportParametersDto paramDto)
        {
            const string procName = "report.TotalPhysicalReadsGet";
            const string columnName = "TotalPhysicalReads";
            var scalars = GetScalars(paramDto, procName, columnName);

            return scalars;
        }

        public List<DatabaseScalarValue> TotalPhysicalWritesGet(ReportParametersDto paramDto)
        {
            const string procName = "report.TotalPhysicalWritesGet";
            const string columnName = "TotalLogicalWrites";
            var scalars = GetScalars(paramDto, procName, columnName);

            return scalars;
        }

        public List<DatabaseScalarValue> TotalWorkerTimeGet(ReportParametersDto paramDto)
        {
            const string procName = "report.TotalWorkerTimeGet";
            const string columnName = "TotalWorkerTimeSeconds";
            var scalars = GetScalars(paramDto, procName, columnName);

            return scalars;
        }


        private List<DatabaseScalarValue> GetScalars(ReportParametersDto paramDto, string storedProcedureName, string columnName)
        {
            var scalars = new List<DatabaseScalarValue>();

            using (var cmd = new SqlCommand())
            {
                using (var conn = new SqlConnection(ConnectionString))
                {
                    conn.Open();
                    using (var tran = conn.BeginTransaction())
                    {
                        cmd.Connection = conn;
                        cmd.Transaction = tran;
                        cmd.CommandTimeout = DbTimeoutSeconds;

                        CreateDateRangeTemporaryTable(cmd);
                        PopulateTemporaryStoredProcedure(paramDto, cmd);

                        SqlCommandCreateScalarSprocCall(paramDto, storedProcedureName, cmd);

                        using (var reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var scalar = CreateScalar(reader, columnName);
                                scalars.Add(scalar);
                            }
                        }

                        tran.Commit();
                    }
                }
            }
            
            return scalars;
        }

        private void PopulateTemporaryStoredProcedure(ReportParametersDto paramDto, SqlCommand cmd)
        {
            string sql = @"
                    
	                declare @startDateKey int;
	                declare @startTimeKey int;
	                exec dbo.ToTemporalKeys @start, @startDateKey out,  @startTimeKey out;

	                declare @endDateKey int;
	                declare @endTimeKey int;
	                exec dbo.ToTemporalKeys @end, @endDateKey out,  @endTimeKey out;

	                insert into #DateRangeOfInterest (DateKey, TimeKey)
	                select
		                dd.DateKey,
		                dt.TimeKey
	                from
		                dbo.DimTime dt
	                cross join dbo.DimDate dd 
	                where
		                dd.DateKey >= @startDateKey
	                and dd.DateKey <= @endDateKey
	                order by 
		                dd.DateKey,
		                dt.TimeKey

	
	                delete from #DateRangeOfInterest where 
		                DateKey = @startDateKey
	                and TimeKey < @startTimeKey

	                delete from #DateRangeOfInterest where 
		                DateKey = @endDateKey
	                and TimeKey > @endTimeKey";

            cmd.CommandText = sql;
            cmd.CommandType = CommandType.Text;
            cmd.Parameters.Add("@start", SqlDbType.DateTime).Value = paramDto.StartDate;
            cmd.Parameters.Add("@end", SqlDbType.DateTime).Value = paramDto.EndDate;

            cmd.ExecuteNonQuery();
        }

        private void CreateDateRangeTemporaryTable(SqlCommand cmd)
        {
            string sql = @"
                    if (object_id('tempdb..#DateRangeOfInterest') is not null) 
	                begin
		                drop table #DateRangeOfInterest;
	                end

	                create table #DateRangeOfInterest
	                (
		                DateKey int,
		                TimeKey int,
		                constraint pk_DateRangeOfInterest primary key clustered (DateKey, TimeKey)
	                )

	                ";

                cmd.CommandText = sql;
                cmd.CommandType = CommandType.Text;

                cmd.ExecuteNonQuery();
        }

        private DatabaseScalarValue CreateScalar(SqlDataReader reader, string columnName)
        {
            var scalar = new DatabaseScalarValue();
            scalar.Name = reader["ProcedureName"].ToString();
            string value = reader[columnName].ToString();
            scalar.Value = double.Parse(value);
            
            return scalar;
        }

        private void SqlCommandCreateScalarSprocCall(ReportParametersDto paramDto, string storedProcedureName, SqlCommand cmd)
        {
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.CommandTimeout = DbTimeoutSeconds;
            cmd.CommandText = storedProcedureName;

            cmd.Parameters.Clear();
            cmd.Parameters.Add("@databaseName", SqlDbType.VarChar, 128).Value = paramDto.DatabaseName;
            cmd.Parameters.Add("@environmentName", SqlDbType.VarChar, 100).Value = paramDto.Enviroment;
            cmd.Parameters.Add("@start", SqlDbType.DateTime).Value = paramDto.StartDate;
            cmd.Parameters.Add("@end", SqlDbType.DateTime).Value = paramDto.EndDate;
        }

        private const string ConnectionStringName = "ReportDatabase";
        private string ConnectionString { get { return ConfigurationManager.ConnectionStrings[ConnectionStringName].ConnectionString;  } }
        private int DbTimeoutSeconds { get { return Settings.Default.DbTimeoutSeconds;} }

    }

}