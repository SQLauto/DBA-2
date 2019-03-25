using System.Collections.Generic;

namespace Deployment.Domain.Operations
{
    public interface IServiceAccountsManager
    {
        bool DecryptServiceAccountFile(string file, string outputPath = null);
        bool EncryptServiceAccountFile(string file, string outputPath = null);
        ServiceAccount GetServiceAccount(string serviceAccountsFile, string accountName);
        IList<ServiceAccount> ParseFile(string file, bool isDecryptedFile = false);
        void Write(IList<ServiceAccount> accounts, string outputXmlFile, bool encryptPasswords);    }
}