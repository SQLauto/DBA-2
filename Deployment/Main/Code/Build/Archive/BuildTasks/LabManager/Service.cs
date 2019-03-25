using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text;
using System.ServiceModel;

namespace LabManager
{
    class Service
    {
        public CustomBuildActivities.LabManagerService.LabManagerSOAPinterfaceSoapClient Client;
        public CustomBuildActivities.LabManagerService.AuthenticationHeader AuthHeader;
        public CustomBuildActivities.LabManagerInternalService.LabManagerSOAPinterfaceSoapClient InternalClient;
        public CustomBuildActivities.LabManagerInternalService.AuthenticationHeader InternalAuthHeader;


        public Service(Details connectionDetails)
        {
            //initialise the service
            ServicePointManager.ServerCertificateValidationCallback += new System.Net.Security.RemoteCertificateValidationCallback(EasyCertCheckCall);

            //initiate binding
            BasicHttpBinding binding = new BasicHttpBinding();
            binding.SendTimeout = TimeSpan.FromMinutes(5);
            binding.OpenTimeout = TimeSpan.FromMinutes(5);
            binding.CloseTimeout = TimeSpan.FromMinutes(5);
            binding.ReceiveTimeout = TimeSpan.FromMinutes(5);
            binding.AllowCookies = false;
            binding.BypassProxyOnLocal = false;
            binding.HostNameComparisonMode = HostNameComparisonMode.StrongWildcard;
            binding.MessageEncoding = WSMessageEncoding.Text;
            binding.TextEncoding = System.Text.Encoding.UTF8;
            binding.TransferMode = TransferMode.Buffered;
            binding.UseDefaultWebProxy = true;

            //needed for https?
            binding.Security.Mode = BasicHttpSecurityMode.Transport;
            binding.Security.Transport.ClientCredentialType = HttpClientCredentialType.None;
            binding.Security.Message.ClientCredentialType = BasicHttpMessageCredentialType.UserName;


            Client = new CustomBuildActivities.LabManagerService.LabManagerSOAPinterfaceSoapClient(binding, new EndpointAddress(connectionDetails.ServiceURL));

            //initiate auth header from Arguments
            AuthHeader = new CustomBuildActivities.LabManagerService.AuthenticationHeader();
            AuthHeader.organizationname = connectionDetails.Organisation ;
            AuthHeader.password = connectionDetails.Password;
            AuthHeader.username = connectionDetails.UserName;
            AuthHeader.workspacename = connectionDetails.Workspace;

            Client = new CustomBuildActivities.LabManagerService.LabManagerSOAPinterfaceSoapClient(binding, new EndpointAddress(connectionDetails.ServiceURL));

            //initiate auth header from Arguments
            InternalAuthHeader = new CustomBuildActivities.LabManagerInternalService.AuthenticationHeader();
            InternalAuthHeader.organizationname = connectionDetails.Organisation;
            InternalAuthHeader.password = connectionDetails.Password;
            InternalAuthHeader.username = connectionDetails.UserName;
            InternalAuthHeader.workspacename = connectionDetails.Workspace;

            InternalClient = new CustomBuildActivities.LabManagerInternalService.LabManagerSOAPinterfaceSoapClient(binding, new EndpointAddress(connectionDetails.InternalServiceURL));

        }



        bool EasyCertCheckCall(object sender, System.Security.Cryptography.X509Certificates.X509Certificate cert, System.Security.Cryptography.X509Certificates.X509Chain chain, System.Net.Security.SslPolicyErrors error)
        {
            return true;
        }

    }
}
