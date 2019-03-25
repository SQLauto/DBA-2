using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    [Serializable]
    [DataContract(Namespace = "")]
    [KnownType(typeof(WebDeploy))]
    public abstract class BaseRole : IBaseRole, IEquatable<BaseRole>
    {
        protected BaseRole()
        {
            Groups = new List<string>();
        }

        [Mandatory]
        [DataMember]
        public string Name { get; set; }
        [Mandatory]
        [DataMember]
        public string RoleType { get; set; }
        [Mandatory]
        [DataMember]
        public string Description { get; set; }
        [Mandatory]
        [DataMember]
        public string Include { get; set; }
        [Mandatory]
        [DataMember]
        public IList<string> Groups { get; protected set; }
        [Mandatory]
        [DataMember]
        public string Configuration { get; set; }

        public virtual bool Equals(BaseRole other)
        {
            if (ReferenceEquals(null, other)) return false;
            if (ReferenceEquals(this, other)) return true;

            return Name.Equals(other.Name, StringComparison.InvariantCultureIgnoreCase)
                && Include.Equals(other.Include, StringComparison.InvariantCultureIgnoreCase);
        }

        public override bool Equals(object other)
        {
            if (ReferenceEquals(null, other)) return false;
            if (ReferenceEquals(this, other)) return true;

            return GetType() == other.GetType() && Equals((BaseRole)other);
        }

        public override int GetHashCode()
        {
            unchecked // Overflow is fine, just wrap
            {
                var hash = 17;
                hash = hash * 23 + (string.IsNullOrEmpty(Name) ? 0 : Name.ToLowerInvariant().GetHashCode());
                hash = hash * 23 + (string.IsNullOrEmpty(Include) ? 0 : Include.ToLowerInvariant().GetHashCode());
                return hash;
            }
        }

        public override string ToString()
        {
            return string.IsNullOrWhiteSpace(RoleType)
                ? string.IsNullOrWhiteSpace(Description)
                    ? "Deployment Role"
                    : Description
                : string.IsNullOrWhiteSpace(Description) ? RoleType : $"{RoleType} ({Description})";
        }
    }

    public interface IBaseRole
    {
        string Name { get; set; }
        string RoleType { get; set; }
        string Description { get; set; }
        string Include { get; set; }
        IList<string> Groups { get; }
        string Configuration { get; set; }
    }

    public interface IFileSystemRole : IBaseRole { }
    public interface IPrerequsiteRole : IBaseRole { }
    public interface IPreDeploymentRole : IBaseRole { }
    public interface IDeploymentRole : IBaseRole { }
    public interface IDatabaseRole : IBaseRole { }
    public interface IPostDeploymentRole : IBaseRole{}
    public interface ICustomTest : IBaseRole {}

}