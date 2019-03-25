using System;

namespace TFL.Deployment.VCloud
{
    public interface IHostSubscriber : IDisposable
    {
        Guid RunspaceId { get; }
    }
}