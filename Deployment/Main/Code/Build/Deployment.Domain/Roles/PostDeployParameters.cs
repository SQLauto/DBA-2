using System;
using System.Collections.Generic;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    public class PostDeployParameters
    {
        public PostDeployParameters(Machine machine)
        {
            Machine = machine;
            ServicePollFrequency = TimeSpan.FromMilliseconds(100);
            ServicePollDuration = TimeSpan.FromMilliseconds(1000);
            ServiceWaitTime = TimeSpan.FromSeconds(60);
        }

        public Machine Machine { get; }

        public DeploymentServer DeploymentMachine { get; set; }

        public bool DisablePostDeploymentTests { get; set; }

        public ServiceAccount TestServiceAccount { get; set; }

        public IList<ServiceAccount> ServiceAccounts { get; set; }

        public string JumpFolder { get; set; }

        public string Environment { get; set; }

        public string DriveLetter { get; set; }

        public DeploymentPlatform TargetPlatform { get; set; }
        public TimeSpan ServicePollFrequency { get; set; }
        public TimeSpan ServicePollDuration { get; set; }
        public TimeSpan ServiceWaitTime { get; set; }
    }

    public struct DeploymentServer
    {
        public DeploymentServer(Machine machine)
        {
            Name = machine?.Name;
            ExternalIpAddress = machine?.ExternalIpAddress;
        }
        public string Name { get; }
        public string ExternalIpAddress { get; }

        public string DeploymentAddress => !string.IsNullOrEmpty(ExternalIpAddress) ? ExternalIpAddress : Name;
    }
}