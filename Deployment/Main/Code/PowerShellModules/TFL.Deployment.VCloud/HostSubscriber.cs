using System;

namespace TFL.Deployment.VCloud
{
    public class HostSubscriber : IHostSubscriber
    {
        public HostSubscriber()
        {
            RunspaceId = System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId;
        }

        public Guid RunspaceId { get; private set; }
        public void Dispose()
        {

        }
    }
}