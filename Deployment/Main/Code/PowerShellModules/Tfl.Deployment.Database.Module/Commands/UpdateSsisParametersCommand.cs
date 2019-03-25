using System;
using System.Data;
using System.Data.SqlClient;
using System.Management.Automation;
using Deployment.Domain;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Database.Commands
{
    [Cmdlet(VerbsData.Update, "SsisParameters")]
    public class UpdateSsisParametersCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
        [ValidateNotNullOrEmpty]
        public string ConnectionString { get; set; }
        [ValidateNotNullOrEmpty]
        [Parameter(Mandatory = true)]
        public string SsisEnvironment { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string Folder { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNull]
        public Parameter Parameter { get; set; }

        protected override void ProcessRecord()
        {
            var type = Parameter.Type.ToLowerInvariant();
            var name = Parameter.Name;
            var value = Parameter.Value;
            var sqlVarType = "int";
            var description = Parameter.Description;

            if (type.Equals("string"))
            {
                value = $"N'{value}'";
                sqlVarType = "nvarchar(4000)";
            }
            else if (type.Equals("date"))
            {
                value = $"CONVERT(DateTime, {value}')";
                sqlVarType = "datetime";
            }
            else if (type.Equals("bool"))
            {
                value = $"N'{value}'";
                sqlVarType = "bit";
            }
            else if (type.StartsWith("int"))
            {
                sqlVarType = "int";
            }

            WriteHost($"Configuring parameter: {name} = {value}");

            var result = true;

            using (var connection = new SqlConnection(ConnectionString))
            {
                var commandText =
                    $"SET NOCOUNT ON; SELECT CASE WHEN EXISTS(SELECT 1 FROM[SSISDB].[Catalog].[Environment_variables] WHERE[Name] = '{name}') THEN 1 ELSE 0 END";

                using (var command = new SqlCommand(commandText, connection))
                {
                    try
                    {
                        connection.Open();
                        var exists = (int) command.ExecuteScalar() == 1;

                        if (exists)
                        {
                            WriteHost($"\tRemoving Environment Variable '{name}'");
                            command.CommandText =
                                $@"SET NOCOUNT ON; EXEC [SSISDB].[catalog].[delete_environment_variable]
									@folder_name = N'{Folder}',
									@environment_name = N'{SsisEnvironment}',
									@variable_name = N'{name}'";

                            command.ExecuteNonQuery();
                        }

                        WriteHost($"\tCreating Environment Variable '{name}'");

                        command.CommandText = $@"SET NOCOUNT ON; DECLARE @valueVar {sqlVarType}; SET @valueVar = {value}; EXEC [SSISDB].[catalog].[create_environment_variable]
                            @folder_name = N'{Folder}',
                            @environment_name = N'{SsisEnvironment}',
                            @variable_name = N'{name}',
                            @data_type = N'{type}',
                            @sensitive = 0,
                            @value = @valueVar,
                            @description = N'{description}'";

                        command.ExecuteNonQuery();
                    }
                    catch (Exception ex)
                    {
                        result = false;
                        WriteError(ex, this, ErrorCategory.InvalidData);
                    }
                }
            }

            WriteObject(result);
        }
    }
}