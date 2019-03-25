using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Security;
using Deployment.Domain;
using Deployment.Domain.Operations;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsCommon.Get, "ServiceAccount")]
    public class GetServiceAccountCommand :PSCmdlet
    {
        [Parameter(Mandatory = true,
            Position = 0,
            ValueFromPipeline = true)]
        public string Path { get; set; }

        [Parameter(Mandatory = true)]
        public string[] Account { get; set; }

        [Parameter(Mandatory = true)]
        public string Password { get; set; }

        [Parameter]
        public SwitchParameter AsPsCredential { get; set; }

        protected override void ProcessRecord()
        {
            var manager = new ServiceAccountsManager(Password);

            var results = new List<ServiceAccount>(Account.Length);
            results.AddRange(Account.Select(key => manager.GetServiceAccount(Path, key)));

            if (AsPsCredential)
            {
                var secureString = ConvertToSecureString(results[0].DecryptedPassword);
                var cred = new PSCredential(results[0].QualifiedUsername, secureString);
                WriteObject(cred);
                return;
            }

            WriteObject(results);
        }

        private SecureString ConvertToSecureString(string password)
        {
            if (password == null)
                throw new ArgumentNullException(nameof(password));

            var securePassword = new SecureString();

            foreach (var c in password)
                securePassword.AppendChar(c);

            securePassword.MakeReadOnly();
            return securePassword;

            //unsafe
            //{
            //    fixed (char* psz = password)
            //        return new SecureString(psz, password.Length);
            //}
        }
    }
}