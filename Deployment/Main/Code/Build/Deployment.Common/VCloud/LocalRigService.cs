using System.Collections.Generic;
using System.Linq;
using com.vmware.vcloud.sdk;
using Deployment.Common.Logging;

namespace Deployment.Common.VCloud
{
    public class LocalRigService : IVirtualPlatform
    {
        private readonly Dictionary<string, string> _externalIpsCache;

        public LocalRigService()
        {
            _externalIpsCache = new Dictionary<string, string>();

        }

        public string GetExternalIpAddress(string rigName, string machineName, IDeploymentLogger logger = null)
        {
            return "localhost";
        }

        public string GetExternalIpAddress(object vApp, string machineName, IDeploymentLogger logger = null)
        {
            return null;
        }

        public IDictionary<string, string> GetExternalIpAdresses(string rigName, IList<string> machineNames, IDeploymentLogger logger = null)
        {
            foreach (
                string machineName in machineNames.Where(machineName => !_externalIpsCache.ContainsKey(machineName)))
                _externalIpsCache.Add(machineName, GetExternalIpAddress(rigName, machineName));

            return _externalIpsCache;
        }

        public IList<string> GetRigNamesForPattern(string rigNamePattern)
        {
            return new List<string>{"localhost"};
        }

        public bool NewVAppFromTemplate(string vAppName, string vAppTemplateName, IDeploymentLogger logger = null)
        {
            return true;
        }

        public object InitialiseVCloudSession(IDeploymentLogger logger = null)
        {
            return null;
        }

        public object InitialiseVCloudSession(string vCloudUrl, string vCloudOrganisation, string vCloudOrgUserName,
            string vCloudOrgPassword, IDeploymentLogger logger = null)
        {
            return null;
        }

        public object GetVapp(string vAppName)
        {
            return null;
        }

        public void Dispose()
        {
        }

        public bool StartVApp(object vApp, IDeploymentLogger logger = null)
        {
            return true;
        }

        public bool StartVApp(string vAppName, IDeploymentLogger logger = null)
        {
            return true;
        }

        public bool DeleteVApp(object vApp, IDeploymentLogger logger = null)
        {
            return true;
        }

        public bool DeleteVApp(string vAppName, IDeploymentLogger logger = null)
        {
            return true;
        }

        public bool StopVApp(object vApp, IDeploymentLogger logger = null)
        {
            return true;
        }

        public bool StopVApp(string vAppName, IDeploymentLogger logger = null)
        {
            return true;
        }
    }
}
