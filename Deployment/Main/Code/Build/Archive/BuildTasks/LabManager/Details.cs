using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;

namespace LabManager
{
    public class Details
    {
        public string Domain { get; set; }
        public string UserName { get; set; }
        public string Password { get; set; }
        public string Organisation { get; set; }
        public string Workspace { get; set; }
        public string TargetWorkspace {get; set; }

        public string Server { get; set; }

        public string ServiceURL
        {
            get
            {
                return string.Format(@"https://{0}/LabManager/SOAP/LabManager.asmx", Server);
            }
        }
        public string InternalServiceURL
        {
            get
            {
                return string.Format(@"https://{0}/LabManager/SOAP/LabManagerInternal.asmx", Server);
            }
        }

        public override string ToString()
        {
            if (string.IsNullOrEmpty(UserName))
            {
                return null;
            }
            else
            {
                return string.Format("Server '{0}' as '{1}' in '{2}'", Server, UserName, Organisation, Workspace);
            }
        }

    }
}
