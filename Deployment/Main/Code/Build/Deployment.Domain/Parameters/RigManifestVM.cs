namespace Deployment.Domain.Parameters
{
    public struct RigManifestVM
    {
        public RigManifestVM(string name, string ipAddress)
        {
            Name = name;
            IpAddress = ipAddress;
        }

        public string Name { get; }
        public string IpAddress { get; }
    }
}