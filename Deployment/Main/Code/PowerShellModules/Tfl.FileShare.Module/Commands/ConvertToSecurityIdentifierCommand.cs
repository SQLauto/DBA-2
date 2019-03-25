using System;
using System.Management.Automation;

namespace Tfl.FileShare.Commands
{
    [Cmdlet(VerbsData.ConvertTo, "SecurityIdentifier")]
    public class ConvertToSecurityIdentifierCommand : PSCmdlet
    {
        [Parameter(Mandatory = true,
             Position = 0,
             ValueFromPipeline = true)]
        [ValidateNotNull]
        [Alias("SID", "SecurityIdentifier")]
        public object InputObject { get; set; }

        protected override void ProcessRecord()
        {
            try
            {
                var manager = new FileShareManager();
                var sid = manager.GetSecurityIdentifier(InputObject);

                WriteObject(sid);
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, ex.GetType().FullName,ErrorCategory.InvalidType,this));
            }
        }
    }
}