using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    [Serializable]
    [DataContract(Namespace = "")]
    [KnownType(typeof(WebSite))]
    [KnownType(typeof(AppPool))]
    //[KnownType(typeof(BaseRole))]
    public class WebDeploy : BaseRole, IDeploymentRole, IPostDeploymentRole
    {
        public WebDeploy(string configuration)
        {
            Site = new WebSite();
            ConfigurationEncryption = new List<WebConfigurationEncryption>();
            Configuration = configuration;
            RoleType = "Web Deployment";
        }

        [DataMember]
        public AppPool AppPool { get; set; }
        [DataMember]
        public WebSite Site { get; private set; }
        public Package Package { get; set; }

        public IList<WebConfigurationEncryption> ConfigurationEncryption { get; set; }

        public WebTestInfo TestInfo { get; set; }
        [Mandatory]
        [DataMember]
        public string RegistryKey { get; set; }
        [DataMember]
        public string AssemblyToVersionFrom { get; set; }
    }

    [Serializable]
    [DataContract(Namespace = "")]
    public class AppPool
    {
        public AppPool()
        {
            RecycleLogEvents = new List<string>();
        }
        [Mandatory]
        [DataMember]
        public string Name { get; set; }
        [DataMember]
        public string ServiceAccount { get; set; }
        [DataMember]
        public int IdleTimeout { get; set; }
        [DataMember]
        public IList<string> RecycleLogEvents { get; set; }
    }

    [Serializable]
    [DataContract(Namespace = "")]
    [KnownType(typeof(VirtualDirectory))]
    [KnownType(typeof(WebApplication))]
    public class WebSite
    {
        [Mandatory]
        [DataMember]
        public string Name { get; set; }
        [Mandatory]
        [DataMember]
        public int Port { get; set; }
        [Mandatory]
        [DataMember]
        public string PhysicalPath { get; set; }
        [DataMember]
        public bool DirectoryBrowsingEnabled { get; set; }
        [DataMember]
        public List<WebAuthenticationMode> AuthenticationModes { get; set; }
        [DataMember]
        public VirtualDirectory VirtualDirectory { get; set; }
        [DataMember]
        public WebApplication Application { get; set; }

    }

    [Serializable]
    [DataContract(Namespace = "")]
    public class VirtualDirectory
    {
        [Mandatory]
        [DataMember]
        public string Name { get; set; }
        [Mandatory]
        [DataMember]
        public string PhysicalPath { get; set; }
    }

    [Serializable]
    [DataContract(Namespace = "")]
    public class WebApplication
    {
        [Mandatory]
        [DataMember]
        public string Name { get; set; }
        [Mandatory]
        [DataMember]
        public string PhysicalPath { get; set; }
    }

    [Serializable]
    [DataContract(Namespace = "")]
    public class Package
    {
        [Mandatory]
        [DataMember]
        public string Name { get; set; }
    }

    [Serializable]
    [DataContract(Namespace = "")]
    [KnownType(typeof(WebTestEndPoint))]
    public class WebTestInfo
    {
        public WebTestInfo()
        {
            EndPoints = new List<WebTestEndPoint>();
        }

        [DataMember]
        public IList<WebTestEndPoint> EndPoints { get; set; }
    }

    [Serializable]
    [DataContract(Namespace = "")]
    public class WebTestEndPoint
    {
        [DataMember]
        public string Value { get; set; }
        [DataMember]
        public string TestIdentity { get; set; }
        [DataMember]
        public string ContentType { get; set; }
        [DataMember]
        public WebAuthenticationMode Authentication { get; set; }
    }

    public enum WebAuthenticationMode
    {
        Anonymous = 0,
        Basic,
        Digest,
        Windows
    }

    [Serializable]
    [DataContract(Namespace = "")]
    public class WebConfigurationEncryption
    {
        [Mandatory]
        [DataMember]
        public string Section { get; set; }
    }


}