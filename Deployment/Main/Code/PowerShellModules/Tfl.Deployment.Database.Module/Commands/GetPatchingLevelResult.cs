using System;
using System.Data;
using System.Data.SqlClient;
using System.Management.Automation;
using Deployment.Database;

namespace Tfl.Deployment.Database.Commands
{
    [Cmdlet(VerbsCommon.Get, "PatchingLevelResult"), OutputType(typeof(PatchingLevelResult))]
    public class GetPatchingLevelResult : PSCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
        [ValidateNotNullOrEmpty]
        public string ConnectionString { get; set; }

        protected override void ProcessRecord()
        {
            var commandText = "deployment.GetPatchingLevelDeterminationResult";
            WriteVerbose("Executing command: " + commandText);

            using (var connection = new SqlConnection(ConnectionString))
            {
                using (var command = new SqlCommand(commandText, connection)
                    .OfType(CommandType.StoredProcedure)
                    .AddOutputParameter("@isValid", DbType.Boolean)
                    .AddOutputParameter("@errorMessage", DbType.String, 4000)
                    .AddOutputParameter("@isAtPatchLevelWhichWasTested", DbType.Boolean))
                {
                    try
                    {
                        connection.Open();
                        var result = command.ExecuteNonQuery();

                        var isValid = command.ReadOutputParameterValue<bool>("@isValid");
                        var isAtPatchLevel = command.ReadOutputParameterValue<bool>("@isAtPatchLevelWhichWasTested");
                        var errorMessage = command.ReadOutputParameterValue<string>("@errorMessage");

                        var parseResult = ParseResult(isValid, isAtPatchLevel, errorMessage);

                        WriteObject(parseResult);
                    }
                    catch (Exception ex)
                    {
                        var errorRecord = new ErrorRecord(ex, Guid.NewGuid().ToString(), ErrorCategory.ConnectionError, this);
                        WriteError(errorRecord);
                    }
                }
            }
        }

        private PatchingLevelResult ParseResult(bool isValid, bool isAtPatchLevel, string message)
        {
            var patchResult = new PatchingLevelResult { IsValid = isValid, IsAtTestedPatchLevel = isAtPatchLevel, ErrorMessage = message };

            return patchResult;
        }
    }
}