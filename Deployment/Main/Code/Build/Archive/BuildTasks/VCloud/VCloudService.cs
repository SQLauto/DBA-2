using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net;
using System.Security.Cryptography.X509Certificates;
using com.vmware.vcloud.api.rest.schema;
using com.vmware.vcloud.sdk;
using Deployment.Utils;

namespace VCloud
{
    class VCloudService : IDisposable
    {
        private readonly vCloudClient _vClient;
        private readonly Organization _organistion;
        private readonly Dictionary<string, string> _externalIpsCache;
        private readonly string _userName;
        private readonly string _password;
        private readonly string _url;
        private readonly string _orgName;
        //private List<ReferenceType> _vAppReferenceTypes;
        //private Vapp _vApp;
        //private List<VM> _vms;

        /// <summary>
        /// Default Constructor
        /// </summary>
        public VCloudService()
        {
            Configuration config = ConfigurationManager.OpenExeConfiguration(this.GetType().Assembly.Location);
            _userName = config.AppSettings.Settings["Testing.vCloud.OrgUsername"].Value;
            _password = config.AppSettings.Settings["Testing.vCloud.OrgPassword"].Value;
            _url = config.AppSettings.Settings["Testing.vCloud.Url"].Value;
            _orgName = config.AppSettings.Settings["Testing.vCloud.Org"].Value;

            _vClient = new vCloudClient(_url, com.vmware.vcloud.sdk.constants.Version.V5_5);
            FakeCertificatePolicy();
            _vClient.Login(string.Format("{0}@{1}", _userName, _orgName), _password);

            Dictionary<string, ReferenceType> orgsList = _vClient.GetOrgRefsByName();
            ReferenceType orgRef = (from org in orgsList
                                    where org.Key.Equals(_orgName, StringComparison.CurrentCultureIgnoreCase)
                                    select org.Value).FirstOrDefault();
            _organistion = Organization.GetOrganizationByReference(_vClient, orgRef);
            if (_organistion == null)
            {
                throw new ApplicationException(string.Format("Can not find organsiation {0}", _orgName));
            }

            _externalIpsCache = new Dictionary<string, string>();

        }

        public bool VerifyVapp(string rigName)
        {
            bool verified = false;

            Vapp vapp = GetVapp(rigName);
            if (vapp != null)
            {
                verified = true;
            }
            else
            {
                verified = false;
            }
            
            return verified;
        }

        public bool VerifyVappTemplate(string templateName)
        {
            bool verified = false;

            VappTemplate VappTemplate = GetVappTemplate(templateName);
            if (VappTemplate != null)
            {
                verified = true;
            }
            else 
            {
                verified = false;
            }

            return verified;
        }

        private Vapp GetVapp(string rigName)
        {
            Vapp vapp;

            try
            {
                ReferenceType vdcRef = _organistion.GetVdcRefs().FirstOrDefault();
                ReferenceType vAppRef = Vdc.GetVdcByReference(_vClient, vdcRef).GetVappRefByName(rigName);
                vapp = Vapp.GetVappByReference(_vClient, vAppRef);
            }
            catch (KeyNotFoundException)
            {
                vapp = null;
            }
            catch(Exception Ex)
            {
                throw Ex;
            }

            return vapp;
        }       

        private VappTemplate GetVappTemplate(string templateName)
        {
            VappTemplate vapptemplate = null;

            ReferenceType vdcRef = _organistion.GetVdcRefs().FirstOrDefault();
            List<ReferenceType> vAppTemplateRefs = Vdc.GetVdcByReference(_vClient, vdcRef).GetVappTemplateRefsByName(templateName);

            if (vAppTemplateRefs.Count > 0)
            {
                foreach (ReferenceType vAppTemplateRef in vAppTemplateRefs)
                {
                    vapptemplate = VappTemplate.GetVappTemplateByReference(_vClient, vAppTemplateRef);
                    if (vapptemplate.Resource.name == templateName)
                    {
                        break;
                    }
                    else
                    {
                        vapptemplate = null;
                    }
                }
            }
            else
            {
                vapptemplate = null;
            }

            return vapptemplate;
        }

        public void Dispose()
        {
            _vClient.Logout();
        }

        private static void FakeCertificatePolicy()
        {
            ServicePointManager.ServerCertificateValidationCallback += ValidateServerCertificate;
        }

        /// <summary>
        /// Defined a function to validate the fake server certificate 
        /// </summary>
        private static bool ValidateServerCertificate(object sender, X509Certificate
        certificate, X509Chain chain, System.Net.Security.SslPolicyErrors sslPolicyErrors)
        {
            return true;
        }
    }
}
