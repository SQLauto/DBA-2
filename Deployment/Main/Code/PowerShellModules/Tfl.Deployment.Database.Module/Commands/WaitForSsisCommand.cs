using System;
using System.Data.SqlClient;
using System.Management.Automation;
using System.Threading;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Database.Commands
{
    [Cmdlet(VerbsLifecycle.Wait, "ForSsis", DefaultParameterSetName = "Project")]
    public class WaitForSsisCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
        [ValidateNotNullOrEmpty]
        public string ConnectionString { get; set; }
        [Parameter(Mandatory=true, ParameterSetName= "Project")]
        public string Project { get; set; }
        [Parameter(Mandatory = true, ParameterSetName = "Environment")]
        public string SsisEnvironment { get; set; }
        [Parameter(Mandatory = true, ParameterSetName = "Package")]
        public string Package { get; set; }
        [Parameter(Mandatory =true, ParameterSetName = "Package")]
        public string Parameter { get; set; }
        [Parameter(Mandatory = true, ParameterSetName = "Project")]
        [Parameter(Mandatory = true, ParameterSetName = "Environment")]
        public string Folder { get; set; }
        [PSDefaultValue(Value = 120)]
        public int WaitForSeconds { get; set; }

        protected override void ProcessRecord()
        {
            var commandText = "SET NOCOUNT ON; ";

            switch (ParameterSetName)
            {
                case "Project":
                {

                    var text = $@"SELECT CASE WHEN EXISTS(SELECT 1 FROM [SSISDB].[catalog].[projects] As P
								LEFT JOIN [SSISDB].[catalog].[folders] As F On P.folder_id = F.folder_id
						WHERE P.[name] = N'{Project}' AND F.[name] = N'{Folder}') THEN 1 ELSE 0 END";

                    commandText = string.Concat(commandText, text);
                    break;
                }

                case "Environment":
                {

                    var text = $@"SELECT CASE WHEN EXISTS(SELECT 1 FROM [SSISDB].[catalog].[environments] As E
								LEFT JOIN [SSISDB].[catalog].[folders] As F On E.folder_id = F.folder_id
						WHERE E.[name] = N'{SsisEnvironment}' AND F.[name] = N'{Folder}') THEN 1 ELSE 0 END";

                    commandText = string.Concat(commandText, text);
                    break;
                }

                case "Package":
                {
                    var text = $@"SELECT CASE WHEN EXISTS(SELECT 1 FROM [SSISDB].[catalog].[object_parameters]
	                        WHERE [parameter_name] = N'{Parameter}' COLLATE SQL_Latin1_General_CP1_CS_AS AND
	                        [object_name] = N'{Package}') THEN 1 ELSE 0 END";

                    commandText = string.Concat(commandText, text);
                    break;
                }
            }

            WriteVerbose("CommandText: " + commandText);

            Thread.Sleep(TimeSpan.FromSeconds(5));

            var loopCount = 0;
            var loopLimit = Math.Ceiling(WaitForSeconds / 5.0d);

            var deployed = false;

            while (loopCount <= loopLimit && !deployed)
            {
                using (var connection = new SqlConnection(ConnectionString))
                {
                    using (var command = new SqlCommand(commandText, connection))
                    {
                        try
                        {
                            connection.Open();
                            deployed = (int)command.ExecuteScalar() == 1;
                        }
                        catch (Exception ex)
                        {
                            WriteError(ex, this, ErrorCategory.InvalidData);
                        }
                    }
                }

                loopCount++;

                if (deployed) continue;

                WriteHost($"SSISDB has not caught up after {loopCount} loops. Waiting...");
                Thread.Sleep(TimeSpan.FromSeconds(5));
            }

            WriteObject(deployed);
        }
    }
}