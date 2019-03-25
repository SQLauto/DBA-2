using System;

namespace Tfl.FileShare
{
    internal sealed class FileShareManager
    {
        public System.Security.Principal.SecurityIdentifier GetSecurityIdentifier(object inputObject)
        {
            System.Security.Principal.SecurityIdentifier principal = null;

            var stringSid = inputObject as string;
            if (stringSid != null)
            {
                principal = new System.Security.Principal.SecurityIdentifier(stringSid);
            }

            var byteSid = inputObject as byte[];

            if (byteSid != null)
            {
                principal = new System.Security.Principal.SecurityIdentifier(byteSid, 0);
            }

            var sid = inputObject as System.Security.Principal.SecurityIdentifier;

            if (sid != null)
            {
                principal = sid;
            }

            if (principal == null)
            {
                throw new InvalidCastException(string.Format("Invalid SID. The `SID` parameter accepts a `System.Security.Principal.SecurityIdentifier` object, a SID in SDDL form as a `string`, or a SID in binary form as byte array. You passed a '{0}'", inputObject.GetType()));
            }

            return principal;
        }
    }
}