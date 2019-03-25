using System;
using System.Text;
using System.Security.Cryptography;
using System.IO;
using System.Runtime.InteropServices;
using System.Security;

namespace Deployment.Common.Helpers
{
    public class EncryptionHelper
    {
        public string ConvertToUnSecureString(SecureString valueToUnsecure)
        {
            var unmanagedString = IntPtr.Zero;
            try
            {
                unmanagedString = Marshal.SecureStringToGlobalAllocUnicode(valueToUnsecure);
                return Marshal.PtrToStringUni(unmanagedString);
            }
            finally
            {
                Marshal.ZeroFreeGlobalAllocUnicode(unmanagedString);
            }
        }

        public SecureString ConvertToSecureString(string valueToSecure)
        {
            var secureString = new SecureString();
            if (valueToSecure.Length <= 0)
                return secureString;

            foreach (var c in valueToSecure.ToCharArray()) secureString.AppendChar(c);
            return secureString;
        }

        public string Encrypt(string data, SecureString password)
        {
            var key = GetKeyFromPassword(ConvertToUnSecureString(password));
            return Convert.ToBase64String(Encrypt(Encoding.UTF8.GetBytes(data), key));
        }

        public string Encrypt(string data, string password)
        {
            var key = GetKeyFromPassword(password);
            return Convert.ToBase64String(Encrypt(Encoding.UTF8.GetBytes(data), key));
        }

        public string Decrypt(string data, SecureString password)
        {
            var key = GetKeyFromPassword(ConvertToUnSecureString(password));
            return Encoding.UTF8.GetString(Decrypt(Convert.FromBase64String(data), key));
        }

        public string Decrypt(string data, string password)
        {
            var key = GetKeyFromPassword(password);
            return Encoding.UTF8.GetString(Decrypt(Convert.FromBase64String(data), key));
        }

        private byte[] Encrypt(byte[] data, byte[] key)
        {
            using (var algorithm = Rijndael.Create())
            {
                //algorithm.Padding = PaddingMode.PKCS7;
                using (var encrypter = algorithm.CreateEncryptor(key, key))
                {
                    return Encrypt(data, encrypter);
                }
            }
        }

        private byte[] Decrypt(byte[] data, byte[] key)
        {
            using (var algorithm = Rijndael.Create())
            {
                //algorithm.Padding = PaddingMode.PKCS7;
                using (var decrypter = algorithm.CreateDecryptor(key, key))
                {
                    return Encrypt(data, decrypter);
                }
            }
        }

        private byte[] Encrypt(byte[] data, ICryptoTransform cryptor)
        {
            using (var memoryStream = new MemoryStream())
            {
                using (var c = new CryptoStream(memoryStream, cryptor, CryptoStreamMode.Write))
                {
                    c.Write(data, 0, data.Length);
                    c.FlushFinalBlock();
                }
                return memoryStream.ToArray();
            }
        }

        // Derive an encryption key from a user supplied password
        // DO NOT CHANGE THIS FUNCTION WITHOUT CONSULTING THE DEPLOYMENT TEAM
        // DOING SO WILL BREAK FUTURE DECRYPTIONS
        private byte[] GetKeyFromPassword(string password)
        {
            byte[] salt = new byte[] { 0, 1, 2, 3, 4, 5, 6, 7 };
            var pwdGen = new Rfc2898DeriveBytes(password, salt, 1000);

            var key = pwdGen.GetBytes(16);

            return key;
        }
    }
}