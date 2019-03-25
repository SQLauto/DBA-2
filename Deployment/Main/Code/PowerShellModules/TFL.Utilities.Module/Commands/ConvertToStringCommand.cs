using System.Management.Automation;
using System.Security;
using Deployment.Common.Helpers;
using Tfl.PowerShell.Common;

namespace TFL.Utilities.Commands
{
    [Cmdlet(VerbsData.ConvertTo, "String")]
    public class ConvertToStringCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNull]
        public SecureString Value { get; set; }
        protected override void ProcessRecord()
        {
            var encryptionHelper = new EncryptionHelper();

            var value = encryptionHelper.ConvertToUnSecureString(Value);

            WriteObject(value);
        }
    }
}