using System;
using System.Management.Automation;
using Deployment.Common.Security;

namespace Tfl.FileShare.Commands
{
    [Cmdlet(VerbsDiagnostic.Resolve, "Identity", DefaultParameterSetName = "ByName")]
    public class ResolveIdentityCommand : PSCmdlet
    {
        [Parameter(Mandatory = true,
             Position = 0,
             ParameterSetName = "ByName")]
        [ValidateNotNull]
        public string Name { get; set; }

        [Parameter(Mandatory = true,
             Position = 0,
             ParameterSetName = "BySid")]
        [ValidateNotNull]
        [Alias("SID", "SecurityIdentifier")]
        public object InputObject { get; set; }
        //The SID of the identity to return. Accepts a SID in SDDL form as a `string`, a `System.Security.Principal.SecurityIdentifier` object, or a SID in binary form as an array of bytes.

        protected override void ProcessRecord()
        {
            try
            {
                Identity identity;

                if (ParameterSetName == "BySid")
                {
                    var manager = new FileShareManager();
                    var sid = manager.GetSecurityIdentifier(InputObject);

                    if (sid == null)
                        return;

                    identity = Identity.FindBySid(sid);

                    if (identity == null)
                    {
                        throw new ItemNotFoundException(string.Format("Identity {0} was not found", sid.Value));
                    }

                    WriteObject(identity);
                    return;
                }

                identity = Identity.FindByName(Name);

                if (identity == null)
                {
                    throw new ItemNotFoundException(string.Format("Identity {0} was not found", Name));
                }

                WriteObject(identity);
            }
            catch (ItemNotFoundException ex)
            {
                WriteError(new ErrorRecord(ex, ex.GetType().FullName, ErrorCategory.ObjectNotFound, this));
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, ex.GetType().FullName, ErrorCategory.InvalidOperation, this));
            }
        }
    }
}