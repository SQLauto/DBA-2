using System;
using System.Collections.Generic;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class ServiceBrokerTest : BaseRole, ICustomTest
    {
        public ServiceBrokerTest()
        {
            RoleType = "Service Broker Test";
            Tests = new List<ServiceBrokerSqlTest>();
        }

        public IList<ServiceBrokerSqlTest> Tests { get; private set; }
    }

    [Serializable]
    public class ServiceBrokerSqlTest
    {
        public string UserName { get; set; }
        public string Password { get; set; }
        public string DatabaseServer { get; set; }
        public string DatabaseInstance { get; set; }
        public string TargetDatabase { get; set; }
        public string SqlScript { get; set; }
    }

}