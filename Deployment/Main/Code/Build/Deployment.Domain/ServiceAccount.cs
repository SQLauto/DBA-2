using System;

namespace Deployment.Domain
{
    [Serializable]
    public class ServiceAccount
    {
        public ServiceAccount()
        {
        }

        public ServiceAccount(string username)
        {
            Username = username;
        }

        /// <summary>
        /// The Name/Key used to lookup account details from the relevant Accounts file.
        /// </summary>
        public string LookupName { get; set; }
        public string EncryptedPassword { get; set; }
        public string DecryptedPassword { get; set; }
        public string Domain { get; set; }
        public string Username { get; set; }
        public string QualifiedUsername => string.IsNullOrWhiteSpace(Domain) ? Username : $@"{Domain}\{Username}";
    }
}