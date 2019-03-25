using System;
using System.Collections.Generic;
using Deployment.Common;

namespace Deployment.Domain.Roles
{
    [Serializable]
    public class SsisDeploy : BaseRole, IDeploymentRole, IPostDeploymentRole
    {
        public SsisDeploy()
        {
            Packages = new List<string>();
            Parameters = new List<Parameter>();
            RoleType = "SSIS Deploy";
        }
        [Mandatory]
        public string ProjectType { get; set; }
        [Mandatory]
        public string ProjectName { get; set; }
        [Mandatory]
        public string SsisFile { get; set; }
        public IList<string> Packages { get; set; }
        public IList<Parameter> Parameters { get; set; }
        public SsisTestInfo TestInfo { get; set; }
        [Mandatory]
        public SsisDepoymentMode DeploymentMode { get; set; }
        public string DestinationFolder { get; set; }
        public string Environment { get; set; }
        public string Folder { get; set; }
        public string DatabaseInstance { get; set; }
    }

    [Serializable]
    public class SsisTestInfo
    {
        public string SqlUserName { get; set; }
        public string SqlPassword { get; set; }
    }

    public enum SsisDepoymentMode
    {
        Sql,
        File,
        Wiz,
        Dts
    }
}