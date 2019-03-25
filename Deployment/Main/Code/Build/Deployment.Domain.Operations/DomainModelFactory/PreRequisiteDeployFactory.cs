using System;
using System.Xml.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class PreRequisiteDeployFactory : BaseRoleFactory<PreRequisiteDeploy>
    {
        public PreRequisiteDeployFactory(string defaultConfig) : base(defaultConfig, new[] {"config:ServerRole[@Name='TFL.ServerPrerequisite']","role:ServerRole[@Name='TFL.ServerPrerequisite']"})
        {

        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new PreRequisiteDeploy(DefaultConfig);

            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                foreach (var element in rootNode.Elements())
                {
                    var elementName = element.Name.LocalName;
                    IPrerequsiteRole role = null;

                    switch (elementName)
                    {
                        case "WindowsServicePrerequisite":
                            role = CreateWindowsServicePreReq(element, ref validationResult);
                            break;
                        default:
                            validationResult.AddError($"Parsing IPrerequsiteRole, unknown element named: {elementName}");
                            break;
                    }

                    if (role == null)
                        continue;

                    ParseCommonAttributes(role, rootNode, ref validationResult);
                    retVal.PreRequisiteRoles.Add(role);
                }

                ValidateDomainObject(retVal, ref validationResult, true);
            }
            catch (Exception ex)
            {
                validationResult.AddException(ex);
                return null;
            }

            return validationResult.Result ? retVal : null;
        }

        private IPrerequsiteRole CreateWindowsServicePreReq(XElement element, ref ValidationResult validationResult)
        {
            var retVal = new WindowsServicePreRequisite(DefaultConfig);
            ParseElementAttribute(element, "ServiceName", () => retVal.ServiceName, ref validationResult, ValidationAction.NotNullOrEmpty("WindowsServicePreRequisite - ServiceName"));
            ParseElementAttribute(element, "State", () => retVal.State, ref validationResult);
            ParseElementAttribute(element, "Action", () => retVal.Action, ref validationResult);

            return retVal;
        }

        public override bool ValidateDomainObject(PreRequisiteDeploy domainObject, ref ValidationResult validationResult,
            bool suppressStandardParseValidations = false)
        {
            return validationResult.Result;
        }
    }
}