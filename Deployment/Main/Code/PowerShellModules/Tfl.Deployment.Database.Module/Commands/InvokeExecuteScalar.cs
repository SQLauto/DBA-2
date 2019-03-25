using System;
using System.Data.SqlClient;
using System.Management.Automation;

namespace Tfl.Deployment.Database.Commands
{
    [Cmdlet(VerbsLifecycle.Invoke, "ExecuteScalar")]
    public class InvokeExecuteScalar : PSCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
        [ValidateNotNullOrEmpty]
        public string ConnectionString { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string CommandText { get; set; }

        protected override void ProcessRecord()
        {
            if (!CommandText.StartsWith("set nocount on;", StringComparison.InvariantCultureIgnoreCase))
            {
                CommandText = "set nocount on;" + CommandText;
            }

            WriteVerbose("CommandText: " + CommandText);

            using (var connection = new SqlConnection(ConnectionString))
            {
                using (var command = new SqlCommand(CommandText, connection))
                {
                    try
                    {
                        connection.Open();
                        var result = command.ExecuteScalar();
                        WriteObject(result);
                    }
                    catch (Exception ex)
                    {
                        var errorRecord = new ErrorRecord(ex, Guid.NewGuid().ToString(), ErrorCategory.ConnectionError, this);
                        WriteError(errorRecord);
                    }
                }
            }
        }
    }
}