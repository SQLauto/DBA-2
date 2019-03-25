using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Activities;
using System.Net;
using CustomBuildActivities.LabManagerInternalService;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Build.Workflow.Activities;
using System.ServiceModel;

namespace LabManager
{
    [BuildActivity(HostEnvironmentOption.All)]
    public sealed class DoesRigTemplateExist : CodeActivity
    {
        //Define the Activity Arguments
        public InArgument<string> URL { get; set; }
        public InArgument<string> Username { get; set; }
        public InArgument<string> Password { get; set; }
        public InArgument<string> Organisation { get; set; }
        public InArgument<string> Workspace { get; set; }
        public InArgument<string> TemplateName { get; set; }
        public OutArgument<Boolean> Result { get; set; }

        protected override void Execute(CodeActivityContext context)
        {
            CustomBuildActivities.CustomType.Credential lmCredentials = new CustomBuildActivities.CustomType.Credential();
            lmCredentials.UserName = context.GetValue(this.Username);
            lmCredentials.Password = context.GetValue(this.Password);
            lmCredentials.Domain = "FAE"; 
            bool verified = false;

            try
            {
                //intialise the LabManager Service
                ServicePointManager.ServerCertificateValidationCallback += new System.Net.Security.RemoteCertificateValidationCallback(EasyCertCheck);

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

                LabManagerSOAPinterfaceSoapClient soapClient = new LabManagerSOAPinterfaceSoapClient(binding, new EndpointAddress(context.GetValue(this.URL)));

                AuthenticationHeader auth = new AuthenticationHeader();
                auth.organizationname = context.GetValue(this.Organisation);
                auth.username = lmCredentials.UserName;
                auth.password = lmCredentials.Password;
                auth.workspacename = context.GetValue(this.Workspace);

                Template[] templates = soapClient.ListTemplates(auth);
                foreach (Template template in templates)
                {
                    if (template.name == context.GetValue(this.TemplateName))
                        verified = true;
                }
            }
            catch(Exception ex)
            {
                context.TrackBuildError(ex.Message);
                verified = false;
            }

            Result.Set(context, verified);
        }

        bool EasyCertCheck(object sender, System.Security.Cryptography.X509Certificates.X509Certificate cert, System.Security.Cryptography.X509Certificates.X509Chain chain, System.Net.Security.SslPolicyErrors error)
        {
            return true;
        }
    }
}
