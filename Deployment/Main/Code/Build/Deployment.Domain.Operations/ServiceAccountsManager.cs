using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Common.Xml;

namespace Deployment.Domain.Operations
{
    public class ServiceAccountsManager : IServiceAccountsManager
    {
        private readonly string _decryptionPassword;
        private readonly IDictionary<string, IList<ServiceAccount>> _serviceAccountMap;
        private readonly IDeploymentLogger _logger;

        public ServiceAccountsManager(string decryptionPassword, IDeploymentLogger logger = null)
        {
            _decryptionPassword = decryptionPassword;
            _logger = logger;
            _serviceAccountMap = new Dictionary<string, IList<ServiceAccount>>();
        }

        public bool EncryptServiceAccountFile(string file, string outputPath = null)
        {
            try
            {
                var outFile = GetFileName(file, true, outputPath);

                if (outFile == null)
                    return false;

                Write(file, outFile);

                _logger?.WriteLine($"File encrypted as '{outFile}'");
            }
            catch (Exception ex)
            {
                _logger?.WriteError(ex.Message);
                return false;
            }

            return true;
        }

        public bool DecryptServiceAccountFile(string file, string outputPath = null)
        {
            try
            {
                var outFile = GetFileName(file, false, outputPath);

                if (outFile == null)
                    return false;

                Write(file, outFile, false);

                _logger?.WriteLine($"File decrypted as '{outFile}'");
            }
            catch (Exception ex)
            {
                _logger?.WriteError(ex.Message);
                return false;
            }

            return true;
        }

        public IList<ServiceAccount> ParseFile(string file, bool isDecryptedFile = false)
        {
            ArgumentHelper.AssertNotNullOrEmpty(file, nameof(file));

            if (_serviceAccountMap.ContainsKey(file))
                return _serviceAccountMap[file];

            if (!File.Exists(file))
            {
                var errorMessage = $"Service accounts file was not found: [{file}]";
                throw new FileNotFoundException(errorMessage, file);
            }

            var serviceAccounts = new List<ServiceAccount>();

            var element = XElement.Load(file);

            var helper = new EncryptionHelper();

            foreach (var accountElement in element.Elements().Where(e => e.Name.LocalName == "account"))
            {
                string accountLookupName = accountElement.ReadAttribute<string>("name");
                string domainName = accountElement.ReadChildElement<string>("username");
                int index = domainName.IndexOfAny(new [] { '\\', '/' });
                string username;
                string domain;

                if (index == -1)
                {
                    username = domainName;
                    domain = string.Empty;
                }
                else
                {
                    domain = domainName.Substring(0, index);
                    username = domainName.Substring(index + 1);
                }

                string password = accountElement.ReadChildElement<string>("password");

                var account = new ServiceAccount
                {
                    LookupName = accountLookupName,
                    Domain = domain,
                    Username = username
                };

                if (isDecryptedFile)
                {
                    account.DecryptedPassword = password;
                    if (!string.IsNullOrWhiteSpace(_decryptionPassword))
                    {
                        account.EncryptedPassword = helper.Encrypt(password, _decryptionPassword);
                    }
                }
                else
                {
                    account.EncryptedPassword = password;
                    if (!string.IsNullOrWhiteSpace(_decryptionPassword))
                    {
                        account.DecryptedPassword = helper.Decrypt(password, _decryptionPassword);
                    }
                }

                serviceAccounts.Add(account);
            }

            _serviceAccountMap.Add(file, serviceAccounts);

            return serviceAccounts;
        }

        private void Write(string file, string outputXmlFile, bool encryptPasswords = true)
        {
            var accounts = ParseFile(file, encryptPasswords);
            Write(accounts, outputXmlFile, encryptPasswords);
        }

        public void Write(IList<ServiceAccount> accounts, string outputXmlFile, bool encryptPasswords)
        {
            var helper = new EncryptionHelper();
            var serviveAccountsNode = new XElement("ServiceAccounts");
            foreach (var account in accounts)
            {
                var password = encryptPasswords
                    ? account.EncryptedPassword
                    : helper.Decrypt(account.EncryptedPassword, _decryptionPassword);

                var accountNode = new XElement("account", new XAttribute("name", account.LookupName),
                    new XElement("username", account.QualifiedUsername),
                    new XElement("password", password)
                    );

                serviveAccountsNode.Add(accountNode);
            }

            var document = new XDocument();
            document.Add(serviveAccountsNode);
            document.Save(outputXmlFile);
        }

        public ServiceAccount GetServiceAccount(string serviceAccountsFile, string accountName)
        {
            var accounts = ParseFile(serviceAccountsFile);

            var serviceAccount = accounts.FirstOrDefault(s => s.LookupName.Equals(accountName, StringComparison.InvariantCultureIgnoreCase));
            return serviceAccount;
        }

        private string GetFileName(string file, bool encrypt, string outputPath = null)
        {
            var fileInfo = new FileInfo(file);

            if (!fileInfo.Exists)
                throw new FileNotFoundException("File was not found", file);

            var name = Path.GetFileNameWithoutExtension(file);
            var extension = fileInfo.Extension;

            //if we are calling encrypt and file has _decrypted in name, use raw name
            var suffix = "_Decrypted";
            var index = name.IndexOf(suffix, StringComparison.InvariantCultureIgnoreCase);

            if(!encrypt && index > -1)
                throw new ArgumentException("You are calling decrypt on a file with _Decrypted in the name. File is already decrypted.");

            if (encrypt)
            {
                if (index == -1)
                {
                    suffix = "_Encrypted";
                }
                else
                {
                    name = name.Substring(0, index);
                    suffix = string.Empty;
                }
            }

            var directory = string.IsNullOrWhiteSpace(outputPath)
                ? fileInfo.DirectoryName
                : Directory.Exists(outputPath)
                    ? outputPath
                    : fileInfo.DirectoryName;

            if (Directory.Exists(directory))
                return Path.Combine(directory, $"{name}{suffix}{extension}");

            _logger?.WriteWarn($"Specified {nameof(outputPath)} directory does not exist. File will be save to source directory");
            return null;
        }
    }
}