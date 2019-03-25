using System;
using Deployment.Common.VCloud;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Deployment.Common.Tests
{
    [TestClass]
    public class VCloudServiceTests
    {
        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [Ignore] //This should ONLY be used for manual testing with VS
        public void TestCreatesAndStartsNewVApp()
        {
            var url = "https://vcloud.onelondon.tfl.local";
            var organisation = "ce_organisation_td";
            var username = "zSVCCEVcloudBuild";
            var password = "P0wer5hell";

            var vCloudService = new VCloudService(url, organisation, username, password);

            var client = vCloudService.InitialiseVCloudSession();

            Assert.IsNotNull(client);

            var vApp = vCloudService.GetVapp("Baseline.Steve_S.Test");

            if (vApp != null)
            {
                var stopped = vCloudService.StopVApp(vApp);
                Assert.IsTrue(stopped);
                var deleted = vCloudService.DeleteVApp(vApp);
                Assert.IsTrue(deleted);
            }

            var created = vCloudService.NewVAppFromTemplate("Baseline.Steve_S.Test", "BaselineRig.Patch3");

            Assert.IsTrue(created);

            var started = vCloudService.StartVApp(vApp);

            Assert.IsTrue(started);

            vApp = vCloudService.GetVapp("Baseline.Steve_S.Test");

            Assert.IsNotNull(vApp);
        }
    }
}
