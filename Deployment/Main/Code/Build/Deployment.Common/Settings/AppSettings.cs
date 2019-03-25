using System;
using System.Configuration;

namespace Deployment.Common.Settings
{
    public static class AppSettings
    {
        public static string ServiceAccountsPassword
            // ReSharper restore InconsistentNaming
            => ConfigurationManager.AppSettings["Testing.ServiceAccountsPassword"];

        public static class WindowsService
        {
            public static int PollFrequency
            {
                get
                {
                    int frequency;
                    if (ConfigurationManager.AppSettings["WindowsService.PollFrequency"] != null)
                    {
                        int.TryParse(ConfigurationManager.AppSettings["WindowsService.PollFrequency"], out frequency);
                    }
                    else
                    {
                        frequency = 0;
                    }
                    return frequency;
                }
            }
            /// <summary>
            /// Gets the configured INTERVAL between pooling loops in miliseconds
            /// </summary>
            public static int PollDuration
            {
                get
                {
                    int duration;
                    if (ConfigurationManager.AppSettings["WindowsService.PollDuration"] != null)
                    {
                        int.TryParse(ConfigurationManager.AppSettings["WindowsService.PollDuration"], out duration);
                    }
                    else
                    {
                        duration = 0;
                    }
                    return duration;
                }
            }

            public static TimeSpan VerificationWaitTime
            {
                get
                {
                    var value = ConfigurationManager.AppSettings["WindowsService.VerificationWaitTime"];
                    if (string.IsNullOrWhiteSpace(value))
                        return TimeSpan.Zero;

                    int duration;
                    var valid = int.TryParse(value, out duration);

                    return valid ? TimeSpan.FromMilliseconds(duration) : TimeSpan.Zero;
                }
            }
        }

        public static class VirtualPlatform
        {
            public static string LabManagerDomain => ConfigurationManager.AppSettings["Testing.TestRigDomain"];

            public static string LabManagerUserName => ConfigurationManager.AppSettings["Testing.TestRigUsername"];

            public static string LabManagerPassword => ConfigurationManager.AppSettings["Testing.TestRigPwd"];

            public static string QualifiedUsername
            {
                get
                {
                    var domain = vCloudDomain;
                    var username = vCloudDomainUserName;

                    return string.IsNullOrWhiteSpace(domain) ? username : $@"{domain}\{username}";
                }
            }

            // ReSharper disable InconsistentNaming
            public static string vCloudDomain
            // ReSharper restore InconsistentNaming
                => ConfigurationManager.AppSettings["Testing.vCloud.TestRigDomain"];

            // ReSharper disable InconsistentNaming
            public static string vCloudDomainUserName
            // ReSharper restore InconsistentNaming
                => ConfigurationManager.AppSettings["Testing.vCloud.TestRigUsername"];

            // ReSharper disable InconsistentNaming
            public static string vCloudDomainPassword
            // ReSharper restore InconsistentNaming
                => ConfigurationManager.AppSettings["Testing.vCloud.TestRigPwd"];

            // ReSharper disable InconsistentNaming
            public static string vCloudOrganisation
            // ReSharper restore InconsistentNaming
                => ConfigurationManager.AppSettings["Testing.vCloud.Org"];

            // ReSharper disable InconsistentNaming
            public static string vCloudOrgUserName
            // ReSharper restore InconsistentNaming
                => ConfigurationManager.AppSettings["Testing.vCloud.OrgUsername"];

            // ReSharper disable InconsistentNaming
            public static string vCloudOrgPassword
            // ReSharper restore InconsistentNaming
                => ConfigurationManager.AppSettings["Testing.vCloud.OrgPassword"];

            // ReSharper disable InconsistentNaming
            public static string vCloudUrl
            // ReSharper restore InconsistentNaming
                => ConfigurationManager.AppSettings["Testing.vCloud.Url"];
        }
    }
}
