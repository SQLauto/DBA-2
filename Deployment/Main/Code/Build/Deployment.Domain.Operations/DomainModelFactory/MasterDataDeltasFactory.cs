using System.Xml.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public sealed class MasterDataDeltasFactory : BaseRoleFactory<MasterDataDeltas>
    {
        public MasterDataDeltasFactory(string defaultConfig) : base(defaultConfig, new [] { "config:ServerRole[@Name='TFL.MasterDataDeltas']", "role:ServerRole[@Name='TFL.MasterDataDeltas']" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new MasterDataDeltas(DefaultConfig);
            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                var assets = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "CopyAssets");
                ParseElementAttribute(assets, "Source", () => retVal.Source, ref validationResult, ValidationAction.NotNullOrEmpty("MasterDataDeltas - Source"));
                ParseElementAttribute(assets, "Subsystem", () => retVal.Subsystem, ref validationResult, ValidationAction.NotNullOrEmpty("MasterDataDeltas - Subsystem"));
                ParseElementAttribute(assets, "Daykeys", retVal.DayKeys, ref validationResult);

                var testInfo = assets.Element(Namespaces.CommonRole.XmlNamespace + "TestInfo");
                if (testInfo != null)
                {
                    ParseElementAttribute(testInfo, "VerificationWaitTimeMilliSeconds", () => retVal.CopyAssetsTestInfo.VerificationWaitTime, ref validationResult);
                    ParseElementValue(testInfo, "Port", Namespaces.CommonRole.XmlNamespace, () => retVal.CopyAssetsTestInfo.Port, ref validationResult, ValidationAction.GreaterThanZero("MasterData - Port"));
                    ParseElementValue(testInfo, "EndPoint", Namespaces.CommonRole.XmlNamespace, () => retVal.CopyAssetsTestInfo.EndPoint, ref validationResult, ValidationAction.NotNullOrEmpty("MasterData - EndPoint"));
                }

                ValidateDomainObject(retVal, ref validationResult, true);
            }
            catch (System.Exception ex)
            {
                validationResult.AddException(ex);
                return null;
            }

            return validationResult.Result ? retVal : null;
        }
    }
}
