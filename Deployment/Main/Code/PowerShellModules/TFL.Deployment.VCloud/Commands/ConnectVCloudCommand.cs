using System.Management.Automation;
using System.Security;
using Deployment.Common.Helpers;
using Deployment.Common.VCloud;
using Tfl.PowerShell.Common;

namespace TFL.Deployment.VCloud.Commands
{
    [Cmdlet(VerbsCommunications.Connect, "VCloud")]
    [OutputType(typeof(HostSubscriber))]
    public class ConnectVCloudCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNull]
        public string Url { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNull]
        public string Organisation { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNull]
        public string Username { get; set; }
        [Parameter(Mandatory = true)]
        [ValidateNotNull]
        public SecureString Password { get; set; }

        protected override void ProcessRecord()
        {
            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);

            var manager = VCloudManager.Instance;

            var vCloudService = new VCloudService(Url, Organisation, Username,
                new EncryptionHelper().ConvertToUnSecureString(Password));

            var client = vCloudService.InitialiseVCloudSession(logger);

            WriteHost("Setting up VCloud manager");
            var subscriber = manager.Initialise(vCloudService);

            WriteObject(subscriber);
        }
    }
}