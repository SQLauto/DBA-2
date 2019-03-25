using System;
using Deployment.Common.VCloud;

namespace TFL.Deployment.VCloud
{
    public class VCloudManager : IDisposable
    {
        private WeakReference _subscriber;
        private VCloudService _service;
        private bool _initialised;
        private static VCloudManager _instance;

        private VCloudManager()
        {
            _service = null;
        }

        public static VCloudManager Instance => _instance ?? (_instance = new VCloudManager());

        public IHostSubscriber Initialise(VCloudService service)
        {
            if (_initialised)
                return _subscriber != null && _subscriber.IsAlive ? (IHostSubscriber)_subscriber.Target : null;

            _service = service;
            _subscriber = new WeakReference(new HostSubscriber());

            _initialised = true;

            return (IHostSubscriber)_subscriber.Target;
        }

        public VCloudService Service => _service;

        public void RemoveSubscriber(IHostSubscriber subscribers)
        {
            if (!_subscriber.IsAlive)
                return;

            var target = (IHostSubscriber)_subscriber.Target;

            target.Dispose();
        }

        public void Dispose()
        {
            _service?.Dispose();

            _service = null;
            _instance = null;
        }
    }
}