using System;
using System.Data;
using System.Data.SqlClient;
using System.Management.Automation;
using System.Xml.Linq;
using Deployment.Common;
using Deployment.Common.Xml;
using Deployment.Database;

namespace Tfl.Deployment.Database.Commands
{
    [Cmdlet(VerbsCommon.Get, "PatchingValidation"), OutputType(typeof(PatchingValidationResult))]
    public class GetPatchingValidation : PSCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
        [ValidateNotNullOrEmpty]
        public string ConnectionString { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNullOrEmpty]
        [ValidateSet("Pre","Post")]
        public string Type { get; set; }

        protected override void ProcessRecord()
        {
            var commandText = string.Concat("deployment.", Type.Equals("Post", StringComparison.InvariantCultureIgnoreCase) ? "GetPatchingPostValidation" : "GetPatchingPreValidation");
            WriteVerbose("Executing command: " + commandText);

            using (var connection = new SqlConnection(ConnectionString))
            {
                using (var command = new SqlCommand(commandText, connection)
                    .OfType(CommandType.StoredProcedure)
                    .AddOutputParameter("@isValid", DbType.Boolean)
                    .AddOutputParameter("@validationResult", DbType.Xml))
                {
                    try
                    {
                        connection.Open();
                        var result = command.ExecuteNonQuery();

                        var isValid = command.ReadOutputParameterValue<bool>("@isValid");
                        var messages = command.ReadOutputParameterValue<string>("@validationResult");

                        var parseResult = ParseResult(isValid, messages);

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

        private PatchingValidationResult ParseResult(bool isValid, string messages)
        {
            var patchResult = new PatchingValidationResult {IsValid = isValid, ValidationType = Type};

            var doc = XDocument.Parse(messages);

            var userMessage = doc.Root.TryReadChildElement<string>("UserMessage");

            patchResult.UserMessage = userMessage.Item2;

            var validationErrors = doc.Root.Elements("ValidationError");

            foreach (var validationError in validationErrors)
            {
                var valid = ParseStringAsBool(validationError.ReadChildElement<string>("IsValid"));

                if (valid)
                    continue;

                var message = validationError.ReadChildElement<string>("ValidationMessage");
                var expected = validationError.TryReadChildElement<int>("ActiveSystemExpectedFailure");

                var validationMessage = Type.Equals("Pre", StringComparison.InvariantCultureIgnoreCase)
                    ? $"[ActiveSystemExpectedFailure: {expected.Item2}]: {message}"
                    : message;

                patchResult.ErrorMessages.Add(validationMessage);
            }

            return patchResult;
        }

        private bool ParseStringAsBool(string s)
        {
            return s.Equals("1");
        }
    }
}