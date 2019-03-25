using System.Xml.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class IisSetupDeployFactory : BaseRoleFactory<IisSetupDeploy>
    {
        public IisSetupDeployFactory(string defaultConfig) : base(defaultConfig, new[] { "config:ServerRole[@Name='TFL.IISSetup']", "role:ServerRole[@Name='TFL.IISSetup']"})
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new IisSetupDeploy(DefaultConfig);
            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                ValidateDomainObject(retVal, ref validationResult, true);
            }
            catch (System.Exception ex)
            {
                validationResult.AddException(ex);
                return null;
            }

            return validationResult.Result ? retVal : null;
        }

        public override bool ValidateDomainObject(IisSetupDeploy domainObject, ref ValidationResult validationResult,
            bool suppressStandardParseValidations = false)
        {
            return validationResult.Result;
        }
    }
}