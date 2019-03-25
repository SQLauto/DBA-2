using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Threading;
using com.vmware.vcloud.api.rest.schema;
using com.vmware.vcloud.sdk;
using com.vmware.vcloud.sdk.admin;
using com.vmware.vcloud.sdk.constants;
using Deployment.Common.Logging;
using Version = com.vmware.vcloud.sdk.constants.Version;

namespace Deployment.Common.VCloud
{
    public class VCloudService : IVirtualPlatform
    {
        private Organization _organisation;
        private string _organisationName;
        private string _password;
        private string _url;
        private string _userName;
        private vCloudClient _vClient;
        private bool _initialised;

        //public VCloudService()
        //{
        //    _userName = AppSettings.VirtualPlatform.vCloudOrgUserName;
        //    _password = AppSettings.VirtualPlatform.vCloudOrgPassword;
        //    _url = AppSettings.VirtualPlatform.vCloudUrl;
        //    _organisationName = AppSettings.VirtualPlatform.vCloudOrganisation;
        //}

        public VCloudService(string vCloudUrl, string vCloudOrganisation, string vCloudOrgUserName,
            string vCloudOrgPassword)
        {
            _url = vCloudUrl;
            _organisationName = vCloudOrganisation;
            _userName = vCloudOrgUserName;
            _password = vCloudOrgPassword;
        }

        public object InitialiseVCloudSession(string vCloudUrl, string vCloudOrganisation,
            string vCloudOrgUserName, string vCloudOrgPassword, IDeploymentLogger logger = null)
        {
            _url = vCloudUrl;
            _organisationName = vCloudOrganisation;
            _userName = vCloudOrgUserName;
            _password = vCloudOrgPassword;

            return InitialiseVCloudSession(logger);
        }

        public object InitialiseVCloudSession(IDeploymentLogger logger = null)
        {
            try
            {
                logger?.WriteLine("Initialising vCloudClient Version 5.5");
                _vClient = new vCloudClient(_url, Version.V5_5);

                logger?.WriteLine("Setting InvalidCertificateAction to Ignore for SSL root cert problem");
                FakeCertificatePolicy();

                logger?.WriteLine($"Connecting to vCloudServer {_url}, Org: {_organisationName}");
                _vClient.Login($"{_userName}@{_organisationName}", _password);

                try
                {
                    logger?.WriteLine("Testing connection to vCloud");
                    var orgsList = _vClient.GetOrgRefsByName();
                    var orgRef = (from org in orgsList
                                  where org.Key.Equals(_organisationName, StringComparison.CurrentCultureIgnoreCase)
                                  select org.Value).FirstOrDefault();
                    _organisation = Organization.GetOrganizationByReference(_vClient, orgRef);

                    if (_organisation == null)
                        throw new ApplicationException($"Can not find organsiation {_organisationName}");
                }
                catch (Exception ex)
                {
                    logger?.WriteSummary("Error Testing Connection with vCloud", LogResult.Fail);
                    logger?.WriteError(ex);
                    throw new Win32Exception(2001, "Error Testing Connection with vCloud");
                }

                logger?.WriteLine($"VCloud has been successfully initialised.");
                _initialised = true;
                return _vClient;
            }
            catch (Exception ex)
            {
                logger?.WriteSummary("Exception in InitialiseVCloudSession", LogResult.Fail);
                logger?.WriteError(ex);
                throw new Win32Exception(2000, "Error in InitialiseVCloudSession");
            }
        }

        public bool Initialised => _initialised;

        public string GetExternalIpAddress(object vApp, string machineName, IDeploymentLogger logger = null)
        {
            if (vApp == null)
                throw new ArgumentNullException(nameof(vApp));

            if (string.IsNullOrEmpty(machineName))
                throw new ArgumentNullException(nameof(machineName));

            try
            {
                var machine = ((Vapp)vApp).GetChildrenVms().SingleOrDefault(vm => vm.Reference.name == machineName);

                if (machine == null)
                    throw new ApplicationException($"Machine {machineName} not found in vApp {((Vapp)vApp).Resource.name}");

                var connections = machine.GetNetworkConnections().FirstOrDefault();

                if (connections == null)
                    throw new ApplicationException($"Machine {machineName} not found in vApp {((Vapp)vApp).Resource.name}");

                return connections.ExternalIpAddress;
            }
            catch (Exception ex)
            {
                logger?.WriteSummary("Exception in GetExternalIpAddress", LogResult.Fail);
                logger?.WriteError(ex);
                throw new Win32Exception(2009, "Exception in GetExternalIpAddress");
            }
        }

        public string GetExternalIpAddress(string vAppName, string machineName, IDeploymentLogger logger = null)
        {
            if (!_initialised)
                InitialiseVCloudSession();

            if (string.IsNullOrEmpty(vAppName))
                throw new ArgumentNullException(nameof(vAppName));

            if (string.IsNullOrEmpty(machineName))
                throw new ArgumentNullException(nameof(machineName));

            var vApp = GetVapp(vAppName);

            return GetExternalIpAddress(vApp, machineName, logger);
        }

        public IDictionary<string, string> GetExternalIpAdresses(string rigName, IList<string> machineNames, IDeploymentLogger logger = null)
        {
            var externalIpsCache = new Dictionary<string, string>();

            foreach (
                var machineName in machineNames.Where(machineName => !externalIpsCache.ContainsKey(machineName)))
                externalIpsCache.Add(machineName, GetExternalIpAddress(rigName, machineName, logger));

            return externalIpsCache;
        }

        public IList<string> GetRigNamesForPattern(string rigNamePattern)
        {
            var vdcRef = _organisation.GetVdcRefs().FirstOrDefault();
            var vAppRefs = Vdc.GetVdcByReference(_vClient, vdcRef).GetVappRefs();

            return vAppRefs.Where(vAppRef => vAppRef.name.Contains(rigNamePattern.Replace("*", string.Empty)))
                .Select(vAppRef => vAppRef.name).ToList();
        }

        public bool NewVAppFromTemplate(string vAppName, string vAppTemplateName, IDeploymentLogger logger = null)
        {
            try
            {
                var vAppTemplate = GetVappTemplate(vAppTemplateName, logger);

                if (vAppTemplate == null)
                {
                    logger?.WriteSummary("Could not create new vApp as template was not found.", LogResult.Fail);
                    return false;
                }

                var instVappTemplateParams = new InstantiateVAppTemplateParamsType
                {
                    name = vAppName,
                    Description = $"vApp {vAppName} cloned from vAppTemplate {vAppTemplateName} at {DateTime.Now}",
                    Source = vAppTemplate.Reference
                };

                logger?.WriteLine(instVappTemplateParams.Description);

                var vdc = Vdc.GetVdcByReference(_vClient, _organisation.GetVdcRefs().FirstOrDefault());

                var vApp = vdc.InstantiateVappTemplate(instVappTemplateParams);
                if (vApp.Tasks.Count > 0)
                    vApp.Tasks[0].WaitForTask(0);
            }
            catch (Exception ex)
            {
                logger?.WriteSummary("Failed to create new vApp from template.", LogResult.Fail);
                logger?.WriteError(ex);
                throw new Win32Exception(2002, "Exception at create of NewVAppFromTemplate");
            }

            return true;
        }

        public bool DeleteVApp(string vAppName, IDeploymentLogger logger = null)
        {
            try
            {
                var vApp = GetVapp(vAppName);

                if (vApp == null)
                    return true;

                ((Vapp)vApp).Delete().WaitForTask(0);

                vApp = GetVapp(vAppName);

                return vApp == null;
            }
            catch (Exception ex)
            {
                logger?.WriteSummary("Error deleting vApp", LogResult.Fail);
                logger?.WriteError(ex);
                throw new Win32Exception(2003, "Exception in DeleteVApp");
            }
        }

        public bool DeleteVApp(object vApp, IDeploymentLogger logger = null)
        {
            try
            {
                if (vApp == null)
                    return true;

                var name = ((Vapp)vApp).Reference.name;

                ((Vapp)vApp).Delete().WaitForTask(0);

                vApp = GetVapp(name);

                return vApp == null;
            }
            catch (Exception ex)
            {
                logger?.WriteSummary("Error deleting vApp", LogResult.Fail);
                logger?.WriteError(ex);
                throw new Win32Exception(2003, "Exception in DeleteVApp");
            }
        }

        public bool DoesVappExist(string vAppName)
        {
            var vApp = GetVapp(vAppName);

            return vApp != null;
        }

        public bool DoesVappTemplateExist(string vAppTemplateName)
        {
            var vAppTemplate = GetVappTemplate(vAppTemplateName);

            return vAppTemplate != null;
        }

        public IList<VM> GetVCloudMachines(string vAppName)
        {
            var vApp = GetVapp(vAppName);

            if (vApp != null)
                return ((Vapp)vApp).GetChildrenVms();
            throw new ApplicationException($"vApp {vAppName} does not exist cannot return list of VMs");
        }

        public VappVerificationResult GetVAppMachineStatus(Vapp vApp, int desiredState)
        {
            if (vApp == null)
            {
                return new VappVerificationResult(false, VappStatus.UNKNOWN.Value(),
                    "VApp was null, so could not get vApp machine state.", "Could not verify vApp.");
            }

            var machines = vApp.GetChildrenVms();
            var machineCount = machines.Count;
            var readyMachines = machines.Count(vm => vm.GetVMStatus().Value() == desiredState);

            var result = machineCount == readyMachines;

            var notes =
                $"{readyMachines} machines out of {machineCount} were in desired state: {ConvertVAppStatusToString(desiredState)}";

            return new VappVerificationResult(result, desiredState, notes, null);

        }

        public void ShareVapp(string vAppName, IList<string> shareWith, string accessLevel, bool asUser)
        {
            List<AccessSettingType> newAccessSettings;
            var admin = _vClient.GetVcloudAdmin();
            var orgRef = admin.GetAdminOrgRefsByName()[_organisation.Reference.name];
            var adminOrg = AdminOrganization.GetAdminOrgByReference(_vClient, orgRef);

            var vApp = GetVapp(vAppName);

            if (vApp == null)
                throw new ApplicationException($"Cannot share vApp {vAppName}, Not found");

            var controlAccess = ((Vapp)vApp).GetControlAccess();

            if (controlAccess.AccessSettings == null)
            {
                controlAccess.AccessSettings = new AccessSettingsType();
                newAccessSettings = new List<AccessSettingType>();
            }
            else
            {
                newAccessSettings = controlAccess.AccessSettings.AccessSetting.ToList();
            }

            foreach (var share in shareWith)
            {
                var newAccess = new AccessSettingType
                {
                    AccessLevel = accessLevel,
                    Subject = new ReferenceType()
                };

                if (asUser)
                {
                    var userRef = adminOrg.GetUserRefByName(share);
                    if (userRef == null)
                        throw new ApplicationException($"Cannot share vApp with user {shareWith}. User not found");

                    newAccess.Subject.href = userRef.href;
                    newAccess.Subject.type = "application/vnd.vmware.admin.user+xml";
                }
                else
                {
                    var groupRef = adminOrg.GetGroupRefByName(share);
                    if (groupRef == null)
                        throw new ApplicationException($"Cannot share vApp with group {shareWith}. Group not found");

                    newAccess.Subject.href = groupRef.href;
                    newAccess.Subject.type = "application/vnd.vmware.admin.group+xml";
                }

                newAccessSettings.Add(newAccess);
            }

            controlAccess.AccessSettings.AccessSetting = newAccessSettings.ToArray();
            ((Vapp)vApp).UpdateControlAccess(controlAccess);
        }

        public void ShareVapp(Vapp vApp, IList<string> shareWith, string accessLevel, bool asUser)
        {
            List<AccessSettingType> newAccessSettings;
            var admin = _vClient.GetVcloudAdmin();
            var orgRef = admin.GetAdminOrgRefsByName()[_organisation.Reference.name];
            var adminOrg = AdminOrganization.GetAdminOrgByReference(_vClient, orgRef);

            var controlAccess = vApp.GetControlAccess();

            if (controlAccess.AccessSettings == null)
            {
                controlAccess.AccessSettings = new AccessSettingsType();
                newAccessSettings = new List<AccessSettingType>();
            }
            else
            {
                newAccessSettings = controlAccess.AccessSettings.AccessSetting.ToList();
            }

            var newAccess = new AccessSettingType
            {
                AccessLevel = accessLevel,
                Subject = new ReferenceType()
            };

            //var xx = asUser
            //    ? shareWith.Select(s => adminOrg.GetUserRefByName(s))
            //    : shareWith.Select(s => adminOrg.GetGroupRefByName(s));

            foreach (var share in shareWith)
            {
                if (asUser)
                {
                    var userRef = adminOrg.GetUserRefByName(share);
                    if (userRef == null)
                        throw new ApplicationException($"Cannot share vApp with user {shareWith}. User not found");

                    newAccess.Subject.href = userRef.href;
                    newAccess.Subject.type = "application/vnd.vmware.admin.user+xml";
                }
                else
                {
                    var groupRef = adminOrg.GetGroupRefByName(share);
                    if (groupRef == null)
                        throw new ApplicationException($"Cannot share vApp with group {shareWith}. Group not found");

                    newAccess.Subject.href = groupRef.href;
                    newAccess.Subject.type = "application/vnd.vmware.admin.group+xml";
                }

                newAccessSettings.Add(newAccess);
            }

            controlAccess.AccessSettings.AccessSetting = newAccessSettings.ToArray();
            vApp.UpdateControlAccess(controlAccess);
        }

        public bool StartVApp(string vAppName, IDeploymentLogger logger = null)
        {
            if (string.IsNullOrEmpty(vAppName))
                throw new ArgumentNullException(nameof(vAppName));

            var vApp = GetVapp(vAppName);

            if (vApp == null)
                throw new ApplicationException(
                    $"Cannot start vApp {vAppName}. No vApp of matching name was found");

            return StartVApp((Vapp)vApp, logger);
        }

        public bool StartVApp(object vApp, IDeploymentLogger logger = null)
        {
            try
            {
                //first determine if Vapp machines already started.
                var verifyResult = GetVAppMachineStatus((Vapp)vApp, VappStatus.POWERED_ON.Value());

                if (verifyResult.Result)
                    return true;

                ((Vapp)vApp).Deploy(true, 0, false).WaitForTask(0);

                vApp = GetVapp(((Vapp)vApp).GetResource().name);

                verifyResult = GetVAppMachineStatus((Vapp)vApp, VappStatus.POWERED_ON.Value());

                return verifyResult.Result;
            }
            catch (Exception ex)
            {
                logger?.WriteSummary("Error starting vApp", LogResult.Fail);
                logger?.WriteError(ex);
                throw new Win32Exception(2010, "Exception in StartvApp");
            }
        }

        public bool StopVApp(string vAppName, IDeploymentLogger logger = null)
        {
            if (string.IsNullOrEmpty(vAppName))
                throw new ArgumentNullException(nameof(vAppName));

            var vApp = GetVapp(vAppName);

            if (vApp == null)
            {
                logger?.WriteWarn($"Cannot stop vApp {vAppName}. No vApp of matching name was found");
                return false;
            }

            return StopVApp((Vapp)vApp, logger);
        }

        public bool StopVApp(object vApp, IDeploymentLogger logger = null)
        {
            if (vApp == null)
                throw new ArgumentNullException(nameof(vApp));

            try
            {
                if (!((Vapp)vApp).IsDeployed())
                {
                    return true;
                }

                //first determine if Vapp machines already stopped.
                var verifyResult = GetVAppMachineStatus((Vapp)vApp, VappStatus.POWERED_OFF.Value());

                if (verifyResult.Result)
                    return true;

                ((Vapp)vApp).Undeploy(UndeployPowerActionType.DEFAULT).WaitForTask(0);

                vApp = GetVapp(((Vapp)vApp).GetResource().name);

                verifyResult = GetVAppMachineStatus((Vapp)vApp, VappStatus.POWERED_OFF.Value());

                return verifyResult.Result;
            }
            catch (Exception ex)
            {
                logger?.WriteSummary("Error stopping vApp", LogResult.Fail);
                logger?.WriteError(ex);
                throw new Win32Exception(2011, "Exception in StopvApp");
            }
        }

        public VappTemplate GetVappTemplate(string vAppTemplateName, IDeploymentLogger logger = null)
        {
            logger?.WriteLine("Gettting vApp template.");

            var vdcRef = _organisation.GetVdcRefs().FirstOrDefault();

            if (vdcRef == null)
                logger?.WriteWarn("Unable to get vdcRef from organisation.");

            var vAppTemplateRefs = Vdc.GetVdcByReference(_vClient, vdcRef).GetVappTemplateRefsByName(vAppTemplateName);

            if (vAppTemplateRefs.IsNullOrEmpty())
            {
                logger?.WriteWarn("Unable to get vAppTemplateRefs for template. Returning null");
                return null;
            }

            var vAppTemplate = VappTemplate.GetVappTemplateByReference(_vClient, vAppTemplateRefs.FirstOrDefault());

            return vAppTemplate;
        }

        public object GetVapp(string vAppName)
        {
            return GetVapp(vAppName, 0);
        }

        private object GetVapp(string vAppName, int retryCount)
        {
            Vapp vApp = null;

            var count = 0;
            var vdcRef = _organisation.GetVdcRefs().FirstOrDefault();

            do
            {
                if (count > 0)
                    Thread.Sleep(TimeSpan.FromMinutes(2));

                try
                {
                    var vAppRefs = Vdc.GetVdcByReference(_vClient, vdcRef).GetVappRefsByName();

                    if (vAppRefs.ContainsKey(vAppName))
                    {
                        var vAppRef = Vdc.GetVdcByReference(_vClient, vdcRef).GetVappRefByName(vAppName);
                        vApp = Vapp.GetVappByReference(_vClient, vAppRef);

                        if (vApp != null)
                            break;

                    }
                }
                catch
                {
                    // ignored
                }

                count++;

            } while (retryCount >= count);

            return vApp;
        }


        public bool FirewallConfiguration(string rigname, bool enableFirewall)
        {
            var vApp = GetVapp(rigname);

            var networkConfigSection = ((Vapp)vApp).GetNetworkConfigSection();
            var vAppNetwork = networkConfigSection.NetworkConfig.ToList();
            var firewallProtocols = new FirewallRuleTypeProtocols();
            var list = new List<FirewallRuleType>();
            var service = new FirewallServiceType();
            var firewallRule = new FirewallRuleType();

            firewallProtocols.Items = new object[] { true};
           
            if (enableFirewall)
            {
                service.DefaultAction = "allow";
                service.LogDefaultAction = false;
                service.IsEnabled = true;

                firewallRule.IsEnabled = true;
                firewallRule.Description = "Block all external access";
                //Destination IP
                firewallRule.Item = "external";
                //Source IP
                firewallRule.Item1 = "internal";
                //Is mandatory, but not being changed so put -1 for any port
                firewallRule.SourcePort = -1;
                firewallRule.Protocols = firewallProtocols;
                var array = new List<ItemsChoiceType> { ItemsChoiceType.Any };
                firewallRule.Protocols.ItemsElementName = array.ToArray();
                firewallRule.Policy = "drop";
                list.Add(firewallRule);
                service.FirewallRule = list.ToArray();

                vAppNetwork[0].Configuration.Features[1] = service;
               
                var task = ((Vapp)vApp).UpdateSection(networkConfigSection);
                task.WaitForTask(0);
                if (task.Resource.status.Equals(TaskStatusType.RUNNING.Value()) ||
                                                task.Resource.status.Equals(TaskStatusType.SUCCESS.Value()))
                {
                    return true;
                }
                return false;
            }
            else
            {
                service.DefaultAction = "allow";
                service.LogDefaultAction = false;
                service.IsEnabled = false;

                firewallRule.IsEnabled = false;
                firewallRule.Description = "allow all external access";
                //Destination IP
                firewallRule.Item = "external";
                //Source IP 
                firewallRule.Item1 = "internal";
                //Mandatory, -1 = any port
                firewallRule.SourcePort = -1;
                firewallRule.Protocols = firewallProtocols;
                var array = new List<ItemsChoiceType> { ItemsChoiceType.Any };
                firewallRule.Protocols.ItemsElementName = array.ToArray();
                firewallRule.Policy = "allow";
                list.Add(firewallRule);
                service.FirewallRule = list.ToArray();

                vAppNetwork[0].Configuration.Features[1] = service;

                var task = ((Vapp)vApp).UpdateSection(networkConfigSection);
                task.WaitForTask(0);

                if (task.Resource.status.Equals(TaskStatusType.SUCCESS.Value()) ||
                    task.Resource.status.Equals(TaskStatusType.RUNNING.Value()))
                {
                    return true;
                }

                return false;
            }
        }

        public void Dispose()
        {
            if (_initialised)
                _vClient.Logout();
        }

        private void FakeCertificatePolicy()
        {
            ServicePointManager.ServerCertificateValidationCallback += ValidateServerCertificate;
        }

        private bool ValidateServerCertificate(object sender, X509Certificate
            certificate, X509Chain chain, SslPolicyErrors sslPolicyErrors)
        {
            return true;
        }

        public string ConvertVAppStatusToString(int statusCode)
        {
            if (VappStatus.INCONSISTENT_STATE.Value() == statusCode)
                return "Inconsistent State";

            if (VappStatus.FAILED_CREATION.Value() == statusCode)
                return "Failed Creation";

            if (VappStatus.MIXED.Value() == statusCode)
                return "Mixed";

            if (VappStatus.POWERED_OFF.Value() == statusCode)
                return "Powered Off";

            if (VappStatus.POWERED_ON.Value() == statusCode)
                return "Powered On";

            if (VappStatus.RESOLVED.Value() == statusCode)
                return "Resolved";

            if (VappStatus.SUSPENDED.Value() == statusCode)
                return "Suspended";

            if (VappStatus.UNKNOWN.Value() == statusCode)
                return "Unknown";

            if (VappStatus.UNRECOGNIZED.Value() == statusCode)
                return "Unrecognized";

            if (VappStatus.WAITING_FOR_INPUT.Value() == statusCode)
                return "Waiting for Input";

            return null;
        }
    }

    public struct VappVerificationResult
    {
        public VappVerificationResult(bool result, int statusCode, string notes, string lastErrorMessage)
        {
            Result = result;
            Notes = notes;
            LastErrorMessage = lastErrorMessage;
            StatusCode = statusCode;
        }

        public bool Result { get; set; }

        public int StatusCode { get; set; }

        public string Notes { get; set; }

        public string LastErrorMessage { get; set; }
    }

    //internal struct VappAccessLevel
    //{
    //    public static readonly string READONLY = "ReadOnly";
    //    public static readonly string CHANGE = "Change";
    //    public static readonly string FULLCONTROL = "FullControl";
    //    public static readonly string NONE = "None";
    //}
}