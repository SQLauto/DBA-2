using System;
using System.Collections.Generic;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class ServiceDeploy : BaseRole, IDeploymentRole, IPostDeploymentRole,IEquatable<ServiceDeploy>
    {
        public ServiceDeploy(string configuration)
        {
            Configuration = configuration;
            MsiDeploy = new MsiDeploy();
            Services = new List<WindowsService>();
            RoleType = "Service Deploy";
        }

         public MsiDeploy MsiDeploy { get; set; }

        public IList<WindowsService> Services { get; set; }

        public bool DisableTests { get; set; }
        public int VerificationWaitTime { get; set; }

        public MsiAction Action
        {
            get { return MsiDeploy.Action; }
            set { MsiDeploy.Action = value; }
        }
        public bool Equals(ServiceDeploy other)
        {
            return other != null
                   && Name.Equals(other.Name, StringComparison.InvariantCultureIgnoreCase)
                   && Include.Equals(other.Include, StringComparison.InvariantCultureIgnoreCase)
                   && Action.Equals(other.Action);
        }

        public override bool Equals(BaseRole other)
        {
            return Equals(other as ServiceDeploy);
        }
    }

    [Serializable]
    public class WindowsService
    {
        public WindowsService()
        {
            StartupType = WindowsServiceStartupType.Disabled;
            //DependsUponServices = new List<ServiceDependancy>();
            Account = new ServiceAccount();
        }

        public string Name { get; set; }
        public string CurrentName { get; set; }
        public WindowsServiceStartupType StartupType { get; set; }

        public ServiceAccount Account { get; set; }

        public bool DisableTests { get; set; }
        public int VerificationWaitTimeMilliSeconds { get; set; }

        //public IList<ServiceDependancy> DependsUponServices { get; set; }
        public ClusterInfo ClusterInfo { get; set; }
    }

    //[Serializable]
    //public class ServiceDependancy
    //{
    //    public ServiceDependancy()
    //    {
    //        TargetMachines = new List<string>();
    //    }
    //    public string ServiceName { get; set; }
    //    //TODO: This should be a composed list of objects, not sure about name either... this needs sorting out.
    //    public IList<string> TargetMachines { get; set; }
    //}

    [Serializable]
    public class ClusterInfo
    {
        public string ResourceName { get; set; }
    }
}