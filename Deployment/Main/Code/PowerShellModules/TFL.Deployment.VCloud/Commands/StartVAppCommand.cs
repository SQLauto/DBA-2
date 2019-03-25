﻿using System.Management.Automation;
using com.vmware.vcloud.sdk;
using Deployment.Common.Exceptions;
using Tfl.PowerShell.Common;

namespace TFL.Deployment.VCloud.Commands
{
    [Cmdlet(VerbsLifecycle.Start, "VApp", DefaultParameterSetName = "ByApp")]
    public class StartVAppCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0, ParameterSetName = "ByApp", ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
        [ValidateNotNull]
        public Vapp VApp { get; set; }
        [Parameter(Mandatory = true, Position = 0, ParameterSetName = "ByName")]
        [ValidateNotNull]
        [Alias("Name")]
        public string RigName { get; set; }

        protected override void ProcessRecord()
        {
            var manager = VCloudManager.Instance;

            var vCloudService = manager.Service;
            //use a dedicated excption, or just do a write error etc.
            if (vCloudService == null || !vCloudService.Initialised)
                throw new VCloudException("VCloud service is null or not initialised.");

            var logger = new PowerShellLogger(WriteHost, WriteWarning, WriteError);

            var name = ParameterSetName.Equals("ByApp") ? VApp.Resource.name : RigName;

            var result = ParameterSetName.Equals("ByApp") ? vCloudService.StartVApp(VApp, logger) : vCloudService.StartVApp(RigName, logger);

            if (!result)
            {
                WriteObject(null);
                return;
            }

            var app = vCloudService.GetVapp(name);
            WriteObject(app);
        }
    }
}