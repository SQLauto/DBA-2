using System;
using System.Collections.Generic;
using com.vmware.vcloud.sdk;
using Deployment.Common.Logging;

namespace Deployment.Common
{
    public interface IVirtualPlatform : IDisposable
    {
        object InitialiseVCloudSession(IDeploymentLogger logger = null);
        object InitialiseVCloudSession(string vCloudUrl, string vCloudOrganisation, string vCloudOrgUserName,
            string vCloudOrgPassword, IDeploymentLogger logger = null);

        string GetExternalIpAddress(string rigName, string machineName, IDeploymentLogger logger = null);
        string GetExternalIpAddress(object vApp, string machineName, IDeploymentLogger logger = null);
        IDictionary<string, string> GetExternalIpAdresses(string rigName, IList<string> machineNames, IDeploymentLogger logger = null);
        IList<string> GetRigNamesForPattern(string rigName);
        bool NewVAppFromTemplate(string vAppName, string vAppTemplateName, IDeploymentLogger logger = null);
        object GetVapp(string vAppName);
        bool StartVApp(object vApp, IDeploymentLogger logger = null);
        bool StartVApp(string vAppName, IDeploymentLogger logger = null);
        bool DeleteVApp(object vApp, IDeploymentLogger logger = null);
        bool DeleteVApp(string vAppName, IDeploymentLogger logger = null);
        bool StopVApp(object vApp, IDeploymentLogger logger = null);
        bool StopVApp(string vAppName, IDeploymentLogger logger = null);
    }
}