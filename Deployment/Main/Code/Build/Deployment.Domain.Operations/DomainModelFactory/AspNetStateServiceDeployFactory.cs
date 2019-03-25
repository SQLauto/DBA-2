using System.Xml.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class AspNetStateServiceDeployFactory : BaseRoleFactory<AspNetStateServiceDeploy>
    {
        public AspNetStateServiceDeployFactory(string defaultConfig) : base(defaultConfig, new[] { "config:ServerRole[@Name='TFL.StateServiceSetup']", "role:ServerRole[@Name='TFL.StateServiceSetup']" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new AspNetStateServiceDeploy(DefaultConfig);
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

        public override bool ValidateDomainObject(AspNetStateServiceDeploy domainObject, ref ValidationResult validationResult,
            bool suppressStandardParseValidations = false)
        {
            return validationResult.Result;
        }
    }
}