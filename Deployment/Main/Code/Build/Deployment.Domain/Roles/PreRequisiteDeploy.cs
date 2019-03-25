using System;
using System.Collections.Generic;
using System.Linq;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class PreRequisiteDeploy : BaseRole, IPrerequsiteRole
    {
        public PreRequisiteDeploy(string configuration)
        {
            Configuration = configuration;
            PreRequisiteRoles = new List<IPrerequsiteRole>();
            RoleType = "Pre-Requisite Deploy";

        }
        public IList<IPrerequsiteRole> PreRequisiteRoles { get; private set; }

        public IList<WindowsServicePreRequisite> WindowsServicePreRequisites => PreRequisiteRoles.OfType<WindowsServicePreRequisite>().ToList();
    }
}