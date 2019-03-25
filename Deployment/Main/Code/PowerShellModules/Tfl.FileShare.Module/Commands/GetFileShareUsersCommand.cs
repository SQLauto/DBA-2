using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using Deployment.Common.Helpers;
using Deployment.Domain;
using Deployment.Domain.Operations;
using Deployment.Domain.Roles;

namespace Tfl.FileShare.Commands
{
    [Cmdlet(VerbsCommon.Get, "FileShareUsers")]
    public class GetFileShareUsersCommand : PSCmdlet
    {
        [Parameter(Mandatory = true,
           Position = 0,
           ValueFromPipeline = true)]
        public FileShareDeploy InputObject { get; set; }

        [Parameter(Mandatory = true)]
        [ValidateSet("Read","Change","Full")]
        public string AccessType { get; set; }

        [Parameter(Mandatory = true)]
        public string Path { get; set; }

        [Parameter(Mandatory = true)]
        public string Password { get; set; }

        protected override void ProcessRecord()
        {
            var manager = new ServiceAccountsManager(Password);

            var results = new List<ServiceAccount>();
            var permissionType = EnumHelper.TryParse<FileSharePermission>(AccessType).Item2;

            results.AddRange(InputObject.Users.Where(u => u.AccountType == FileShareUserAccountType.ServiceAccount && u.Permissions == permissionType)
                .Select(key => manager.GetServiceAccount(Path, key.Name)));

            results.AddRange(InputObject.Users.Where(u => u.AccountType == FileShareUserAccountType.DomainAccount && u.Permissions == permissionType).Select(key=>new ServiceAccount(key.Name)));

            WriteObject(results);
        }
    }
}