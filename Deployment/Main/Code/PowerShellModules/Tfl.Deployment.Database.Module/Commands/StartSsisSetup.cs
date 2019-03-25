using System;
using System.Data.SqlClient;
using System.Globalization;
using System.Management.Automation;
using System.Reflection;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Database.Commands
{
    [Cmdlet(VerbsLifecycle.Start, "SsisSetup")]
    public class StartSsisSetup : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
        [ValidateNotNullOrEmpty]
        public string ConnectionString { get; set; }
        [ValidateNotNullOrEmpty]
        [Parameter(Mandatory = true)]
        public string SsisDatabase { get; set; }
        [ValidateNotNullOrEmpty]
        [Parameter(Mandatory = true)]
        public string Password { get; set; }

        private Assembly _assembly;

        protected override void ProcessRecord()
        {
            //we are doing this dynamically as it avoids us having to install this on build server.
            var longName = "Microsoft.SqlServer.Management.IntegrationServices, Version=11.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91";
            _assembly = Assembly.Load(longName);

            var commandText = $"SET NOCOUNT ON; SELECT [Name] FROM sysdatabases WHERE Name = '{SsisDatabase}'";

            var dbName = ExecuteScalar<string>(commandText);

            if (dbName != null && dbName.Equals(SsisDatabase, StringComparison.InvariantCultureIgnoreCase))
                return;

            WriteHost($"{SsisDatabase} does not exist, creating...");

            WriteHost("Enabling CLR");
            ExecuteNonQuery("sp_configure 'clr enabled', 1;");
            ExecuteNonQuery("RECONFIGURE;");

            WriteHost("Creating SSIS Catalog");

            var connecion = new SqlConnection(ConnectionString);

            var integrationServices = CreateInstance(
                "Microsoft.SqlServer.Management.IntegrationServices.IntegrationServices", new object[] {connecion});

            dynamic catalog = CreateInstance("Microsoft.SqlServer.Management.IntegrationServices.Catalog",
                new[] {integrationServices, SsisDatabase, Password });

            catalog.Create();
        }

        private T ExecuteScalar<T>(string commandText)
        {
            using (var connection = new SqlConnection(ConnectionString))
            {
                using (var command = new SqlCommand(commandText, connection))
                {
                    try
                    {
                        connection.Open();
                        var result = (T)command.ExecuteScalar();
                        return result;
                    }
                    catch (Exception ex)
                    {
                        var errorRecord = new ErrorRecord(ex, Guid.NewGuid().ToString(), ErrorCategory.ConnectionError, this);
                        WriteError(errorRecord);
                        return default(T);
                    }
                }
            }
        }

        private bool ExecuteNonQuery(string commandText)
        {
            using (var connection = new SqlConnection(ConnectionString))
            {
                using (var command = new SqlCommand(commandText, connection))
                {
                    try
                    {
                        connection.Open();
                        command.ExecuteScalar();
                        return true;
                    }
                    catch (Exception ex)
                    {
                        var errorRecord = new ErrorRecord(ex, Guid.NewGuid().ToString(), ErrorCategory.ConnectionError, this);
                        WriteError(errorRecord);
                        return false;
                    }
                }
            }
        }

        private object CreateInstance(string instance, object[] args)
        {
            var retVal = _assembly.CreateInstance(instance, false, BindingFlags.CreateInstance, null, args, CultureInfo.CurrentCulture, null);

            return retVal;
        }
    }
}