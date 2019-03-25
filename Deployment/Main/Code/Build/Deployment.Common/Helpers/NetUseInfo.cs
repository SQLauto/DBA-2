namespace Deployment.Common.Helpers
{
    public class NetUseInfo
    {
        public NetUseInfo(string remote, NetUseStatus status, string device, string username)
        {
            Status = status;
            Device = device;
            Remote = remote;
            User = username;
        }

        public NetUseStatus Status { get; }
        public string Device { get; }
        public string Remote { get; }
        public string User { get;  }

    }

    public enum NetUseStatus
    {
        Ok = 0,
        Paused = 1,
        Disconnected = 2,
        NetError = 3,
        Connection = 4,
        ReConnection = 5
    }
}