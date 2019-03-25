using System;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class WindowsServicePreRequisite : BaseRole, IPrerequsiteRole
    {
        public WindowsServicePreRequisite(string configuration)
        {
            Configuration = configuration;
        }

        public string ServiceName { get; set; }
        public WindowsServiceStateType State { get; set; }
        public WindowsServiceActionType Action { get; set; }
    }
}