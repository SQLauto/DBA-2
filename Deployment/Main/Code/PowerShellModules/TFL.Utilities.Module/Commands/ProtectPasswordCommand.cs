﻿using System.Management.Automation;
using System.Security;
using Deployment.Common.Helpers;

namespace TFL.Utilities.Commands
{
    [Cmdlet(VerbsSecurity.Protect, "Password")]
    public class ProtectPasswordCommand : PSCmdlet
    {
        [Parameter(Mandatory = true,
             Position = 0)]
        [ValidateNotNull]
        [Alias("Password")]
        public SecureString EncryptionPassword { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNull]
        public string Value { get; set; }
        [Parameter]
        public SwitchParameter AsSecureString { get; set; }

        protected override void ProcessRecord()
        {
            var encryptionHelper = new EncryptionHelper();

            var value = encryptionHelper.Encrypt(Value, EncryptionPassword);

            if (AsSecureString)
                WriteObject(encryptionHelper.ConvertToSecureString(value));
            else
                WriteObject(value);
        }
    }
}