using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Activities;
using System.Net;
using CustomBuildActivities.LabManagerService;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Build.Workflow.Activities;
using System.ServiceModel;

namespace CustomBuildActivities.Activities.LabManager
{

    [BuildActivity(HostEnvironmentOption.All)]
    public sealed class LabManagerTest : CodeActivity
    {
        // Define the activity arguments of type string
        public InArgument<string> URL { get; set; }
        public InArgument<CustomBuildActivities.CustomType.Credential> Credentials { get; set; }
        public InArgument<string> Organisation { get; set; }
        public InArgument<string> Workspace { get; set; }

        // If your activity returns a value, derive from CodeActivity<TResult>
        // and return the value from the Execute method.
        protected override void Execute(CodeActivityContext context)
        {
            try
            {
                // Obtain the runtime value of the arguments
                string lmURL = context.GetValue(this.URL);
                string lmOrganisation = context.GetValue(this.URL);
                string lmWorkspace = context.GetValue(this.Workspace);
                CustomBuildActivities.CustomType.Credential lmCreds = context.GetValue(this.Credentials);

                //initialise the service
                ServicePointManager.ServerCertificateValidationCallback += new System.Net.Security.RemoteCertificateValidationCallback(EasyCertCheck);

                //initiate binding
                BasicHttpBinding binding = new BasicHttpBinding();
                binding.SendTimeout = TimeSpan.FromMinutes(1);
                binding.OpenTimeout = TimeSpan.FromMinutes(1);
                binding.CloseTimeout = TimeSpan.FromMinutes(1);
                binding.ReceiveTimeout = TimeSpan.FromMinutes(10);
                binding.AllowCookies = false;
                binding.BypassProxyOnLocal = false;
                binding.HostNameComparisonMode = HostNameComparisonMode.StrongWildcard;
                binding.MessageEncoding = WSMessageEncoding.Text;
                binding.TextEncoding = System.Text.Encoding.UTF8;
                binding.TransferMode = TransferMode.Buffered;
                binding.UseDefaultWebProxy = true;

                LabManagerSOAPinterfaceSoapClient soapClient = new LabManagerSOAPinterfaceSoapClient(binding, new EndpointAddress(lmURL));

                //initiate auth header from Arguments
                AuthenticationHeader authHeader = new AuthenticationHeader();
                authHeader.organizationname = lmOrganisation;
                authHeader.password = lmCreds.Password;
                authHeader.username = lmCreds.UserName;
                authHeader.workspacename = lmWorkspace;


                //display a list of configurations available
                Configuration[] rigConfigurations;
                rigConfigurations = soapClient.ListConfigurations(authHeader, 1);
                foreach (Configuration cfg in rigConfigurations)
                {
                    //Console.WriteLine("{0} : {1}", cfg.id, cfg.name);
                    context.TrackBuildWarning(string.Format("Configuration Found", cfg.id, cfg.name));
                }
            }
            catch (Exception ex)
            {
                context.TrackBuildError(ex.Message + ":" + ex.StackTrace);
            }

        }

        bool EasyCertCheck(object sender, System.Security.Cryptography.X509Certificates.X509Certificate cert, System.Security.Cryptography.X509Certificates.X509Chain chain, System.Net.Security.SslPolicyErrors error)
        {
            return true;
        }


    }
}