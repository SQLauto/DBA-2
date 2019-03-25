using System;
using System.Collections.Generic;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class MasterDataDeltas : BaseRole, IDeploymentRole, IPostDeploymentRole
    {
        public MasterDataDeltas(string configuration)
        {
            Configuration = configuration;
            RoleType = "Master Data Deltas Deploy";
            DayKeys = new List<string>();
            Filter = "*.*";
            CopyAssetsTestInfo = new CopyAssetsTestInfo();
        }

        /// <summary>
        /// Source Location
        /// </summary>
        [Mandatory]
        public string Source { get; set; }

        public IList<string> DayKeys { get; }

        [Mandatory]
        public string Subsystem { get; set; }

        public string Filter { get; }

        public CopyAssetsTestInfo CopyAssetsTestInfo { get; }
    }

    [Serializable]
    public class CopyAssetsTestInfo // MasterDataDeltasTestInfo
    {
        [Mandatory]
        public int Port { get; set; }

        [Mandatory]
        public string EndPoint { get; set; }

        public int? VerificationWaitTime { get; set; }
    }
}