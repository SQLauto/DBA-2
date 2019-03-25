using System;
using System.Runtime.InteropServices;
using System.Security.Policy;

namespace Deployment.Common.VCloud
{
    public interface IVirtualPlatformFactory
    {
        IVirtualPlatform GetTargetVirtualPlatform();
    }

    public class VirtualPlatformFactory : IVirtualPlatformFactory
    {
        private readonly DeploymentPlatform _deploymentPlatform;

        public VirtualPlatformFactory(DeploymentPlatform deploymentPlatform = DeploymentPlatform.VCloud)
        {
            _deploymentPlatform = deploymentPlatform;
        }

        public IVirtualPlatform GetTargetVirtualPlatform()
        {
            switch (_deploymentPlatform)
            {
                case DeploymentPlatform.CurrentDomain:
                    return new LocalRigService();
                case DeploymentPlatform.VCloud:
                    var vCloudService = new VCloudService("https://vcloud.onelondon.tfl.local", "ce_organisation_td",
                        "zSVCCEVcloudBuild", "P0wer5hell");
                    vCloudService.InitialiseVCloudSession();
                    return vCloudService;
                case DeploymentPlatform.Azure:
                    return new AzureService();
                default:
                    throw new ApplicationException(
                        $"Platform '{_deploymentPlatform.Description()}' not recognised as a virtual platform, we should never get here");
            }
        }
    }
}