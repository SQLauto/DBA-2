using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading;
using Deployment.Common.Logging;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using Newtonsoft.Json.Linq;

namespace Deployment.Common.VCloud
{
    internal enum VAppAction
    {
        [Description("Stop")] Stop = 0,
        [Description("Start")] Start,
        [Description("Delete")] Delete
    }

    internal class AzureAutomationToken
    {
        public static readonly string VAppAction = "RORYEnvtfzg%2bOdbcS%2b5maye3Yw7JW42v63XMWCqNMn8%3d";

        public static readonly string NewLab = "1hAXlbtdCnaV6tvqzScPm0vu7cpMbkw6idoGRy5E6pQ%3d";

        public static readonly string NewLabVm = "ohSJJBMmpYozECAneHiXQ06gQN7zQ1eTdD9%2basojRQs%3d";

        public static readonly string LabVmExtension = "x%2fGXtJ5KgZnh3KNP4f8EVHs%2fS7aaxd8sHLS61ypIbbw%3d";
    }

    public class AzureService : IVirtualPlatform
    {
        private const string ClientId = "06863203-99bc-49c5-824c-9a5963ae03c9";
        private const string SecretKey = "xw/bCW8OmJihls7MBtiCMcy3ikHbFexFFVMZEaOf5Co=";
        private const string TenantId = "1fbd65bf-5def-4eea-a692-a089c255346b";
        private const string SubscriptionId = "3065ef51-6e69-4ee9-a407-b2cc275f91d6";
        private string _token;

        public AzureService()
        {
            _token = GetBearerToken();
        }

        public void Dispose()
        {
            _token = null;
        }

        public object InitialiseVCloudSession(IDeploymentLogger logger = null)
        {
            throw new NotImplementedException();
        }

        public object InitialiseVCloudSession(string vCloudUrl, string vCloudOrganisation, string vCloudOrgUserName,
            string vCloudOrgPassword, IDeploymentLogger logger = null)
        {
            throw new NotImplementedException();
        }

        public string GetExternalIpAddress(string rigName, string machineName, IDeploymentLogger logger = null)
        {
            return GetVirtualMachine(rigName, machineName);
        }

        public string GetVirtualMachine(string rigName, string machineName)
        {
            var resourceId =
                string.Format(
                    "/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.DevTestLab/labs/{1}/virtualMachines/{2}?api-version=2016-05-15",
                    SubscriptionId, rigName, machineName);

            var rgres2 = JObject.Parse(ProcessRequest(resourceId));
            var computeId = rgres2["properties"]["computeId"].Value<string>();

            return GetVirtualNetwork(computeId);
        }

        public string GetVirtualNetwork(string resourceId)
        {
            resourceId = resourceId.Replace("Microsoft.Compute/virtualMachines", "Microsoft.Network/networkInterfaces") + "?api-version=2015-06-15";

            var rgres2 = JObject.Parse(ProcessRequest(resourceId));
            var ipaddress = rgres2["properties"]["ipConfigurations"][0]["properties"]["privateIPAddress"].Value<string>();

            return ipaddress;
        }

        string ProcessRequest(string url)
        {
            using (var httpClient = new HttpClient { BaseAddress = new Uri("https://management.azure.com") })
            {
                httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _token);

                var request = httpClient.GetAsync(url).Result;

                return !request.IsSuccessStatusCode ? string.Empty : request.Content.ReadAsStringAsync().Result;
            }
        }

        public string GetExternalIpAddress(object vApp, string machineName, IDeploymentLogger logger = null)
        {
            return GetExternalIpAddress(vApp.ToString(), machineName, logger);
        }

        public IDictionary<string, string> GetExternalIpAdresses(string rigName, IList<string> machineNames,
            IDeploymentLogger logger = null)
        {
            var externalIpsCache = new Dictionary<string, string>();
            foreach (var machineName in machineNames)
            {
                externalIpsCache.Add(machineName, GetVirtualMachine(rigName, machineName));
            }

            return externalIpsCache;
        }


        public IList<string> GetRigNamesForPattern(string rigName)
        {
            return GetRigNames().Where(x => x.IndexOf(rigName, StringComparison.CurrentCultureIgnoreCase) >= 0)
                .ToList();
        }

        public bool NewVAppFromTemplate(string vAppName, string vAppTemplateName, IDeploymentLogger logger = null)
        {
            throw new NotImplementedException();
            /*
            var templateInfo = vAppTemplateName.Split('.');
            var projectName = templateInfo[0];
            var templateName = templateInfo[1];

            return ProvisionAction(AzureAutomationToken.NewLab,
                       new
                       {
                           Name = vAppName,
                           ProjectName = projectName,
                           TemplateName = templateName,
                           Servers = new List<object>()
                       }, logger) &&
                   ProvisionAction(AzureAutomationToken.NewLabVm,
                       new
                       {
                           Name = vAppName,
                           ProjectName = projectName,
                           TemplateName = templateName,
                           ForceRefresh = true
                       }, logger) &&
                   ProvisionAction(AzureAutomationToken.LabVmExtension,
                       new {Name = vAppName, ProjectName = projectName}, logger);
            */
        }

        public object GetVapp(string vAppName)
        {
            throw new NotImplementedException();
        }

        public bool StartVApp(object vApp, IDeploymentLogger logger = null)
        {
            return StartVApp(vApp.ToString(), logger);
        }

        public bool StartVApp(string vAppName, IDeploymentLogger logger = null)
        {
            return InvokeVAppAction(vAppName, VAppAction.Start.ToString(), logger);
        }

        public bool DeleteVApp(object vApp, IDeploymentLogger logger = null)
        {
            return DeleteVApp(vApp.ToString(), logger);
        }

        public bool DeleteVApp(string vAppName, IDeploymentLogger logger = null)
        {
            return InvokeVAppAction(vAppName, VAppAction.Delete.ToString(), logger);
        }

        public bool StopVApp(object vApp, IDeploymentLogger logger = null)
        {
            return StopVApp(vApp.ToString(), logger);
        }

        public bool StopVApp(string vAppName, IDeploymentLogger logger = null)
        {
            return InvokeVAppAction(vAppName, VAppAction.Stop.ToString(), logger);
        }


        private IEnumerable<string> GetRigNames()
        {
            var rigs = new List<string>();
            using (var httpClient = new HttpClient {BaseAddress = new Uri("https://management.azure.com")})
            {
                httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _token);

                var url = $"/subscriptions/{SubscriptionId}/providers/Microsoft.DevTestLab/labs?api-version=2016-05-15";
                var request = httpClient.GetAsync(url).Result;

                if (!request.IsSuccessStatusCode) throw new HttpRequestException(request.ReasonPhrase);
                var rgres = request.Content.ReadAsStringAsync().Result;

                var rgres2 = JObject.Parse(rgres);

                foreach (var jToken in (JArray) rgres2["value"])
                {
                    var row = (JObject) jToken;
                    rigs.Add(row["name"].Value<string>());
                }
            }

            return rigs;
        }

        private static string InvokeWebhook(string token, object requestObject, IDeploymentLogger logger)
        {
            var uri = $"https://s9events.azure-automation.net/webhooks?token={token}";
            var client = new HttpClient();
            var response = client.PostAsJsonAsync(uri, requestObject).Result;
            response.EnsureSuccessStatusCode();

            if (!response.IsSuccessStatusCode) throw new HttpRequestException(response.ReasonPhrase);

            var rgres = response.Content.ReadAsStringAsync().Result;

            var rgres2 = JObject.Parse(rgres);
            var jobId = ((JArray) rgres2["JobIds"])[0];
            return jobId.ToObject<string>();
        }

        private string GetAzureJobStatus(string jobId, IDeploymentLogger logger)
        {
            var AutomationResourceGroup = "sso-poc-common";
            var AutomationAccountName = "rig-manager";
            using (var httpClient = new HttpClient {BaseAddress = new Uri("https://management.azure.com")})
            {
                httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _token);

                var url =
                    $"/subscriptions/{SubscriptionId}/resourceGroups/{AutomationResourceGroup}/providers/Microsoft.Automation/automationAccounts/{AutomationAccountName}/jobs/{jobId}?api-version=2015-10-31";
                var request = httpClient.GetAsync(url).Result;

                if (!request.IsSuccessStatusCode) throw new HttpRequestException(request.ReasonPhrase);
                var rgres = request.Content.ReadAsStringAsync().Result;

                var rgres2 = JObject.Parse(rgres);

                return rgres2["properties"]["status"].ToObject<string>();
            }
        }

        private bool InvokeVAppAction(string vAppName, string action, IDeploymentLogger logger)
        {
            vAppName = vAppName.Replace(".", "_");
            return ProvisionAction(AzureAutomationToken.VAppAction, new {LabName = vAppName, Action = action.ToLower()},
                logger);
        }

        private bool ProvisionAction(string actionToken, object requestObject, IDeploymentLogger logger)
        {
            var jobId = InvokeWebhook(actionToken,
                requestObject,
                logger);

            var status = GetAzureJobStatus(jobId, logger);

            logger?.WriteLine($"Job : {jobId} is  {status}");

            var statusList = new[] {"Completed", "Stopped", "Suspended", "Failed"};
            while (!statusList.Contains(status))
            {
                Thread.Sleep(TimeSpan.FromMilliseconds(30));
                status = GetAzureJobStatus(jobId, logger);
                logger?.WriteLine($"Job : {jobId} is  {status}");
            }

            return status.Equals("Completed");
        }

        private static string GetBearerToken()
        {
            var authContext = new AuthenticationContext($"https://login.windows.net/{TenantId}/");
            var clientCredential = new ClientCredential(ClientId, SecretKey);
            var tokenResponse = authContext.AcquireTokenAsync("https://management.core.windows.net/",
                clientCredential).Result;
            var accessToken = tokenResponse.AccessToken;

            return accessToken;
        }
    }
}