using System;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class AppFabricTest : BaseRole, ICustomTest
    {
        public AppFabricTest()
        {
            RoleType = "AppFabric Test";
        }
        public string AccountName { get; set; }
        public string HostName { get; set; }
        public string CacheName { get; set; }
    }
}