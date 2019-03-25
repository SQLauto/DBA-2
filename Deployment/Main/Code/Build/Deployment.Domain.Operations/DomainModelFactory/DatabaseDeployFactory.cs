using System;
using System.Xml.Linq;
using System.Xml.XPath;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class DatabaseDeployFactory : BaseRoleFactory<DatabaseDeploy>
    {
        public DatabaseDeployFactory(string defaultConfig) : base(defaultConfig, new[] { "config:DatabaseRole", "role:DatabaseRole" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement domainModelElement, ref ValidationResult validationResult)
        {
            var retVal = new DatabaseDeploy {Configuration = DefaultConfig};

            try
            {
                ParseCommonAttributes(retVal, domainModelElement, ref validationResult);

                ParseElementValue(domainModelElement, "TargetDatabase", Namespaces.CommonRole.XmlNamespace, () => retVal.TargetDatabase, ref validationResult);
                ParseElementValue(domainModelElement, "DatabaseInstance", Namespaces.CommonRole.XmlNamespace, () => retVal.DatabaseInstance, ref validationResult);
                ParseElementValue(domainModelElement, "BaselineDeployment", Namespaces.CommonRole.XmlNamespace, () => retVal.BaselineDeployment, ref validationResult);
                ParseElementValue(domainModelElement, "PreDeployment", Namespaces.CommonRole.XmlNamespace, () => retVal.PreDeployment, ref validationResult);
                ParseElementValue(domainModelElement, "PatchDeployment", Namespaces.CommonRole.XmlNamespace, () => retVal.PatchDeployment, ref validationResult);
                ParseElementValue(domainModelElement, "PostDeployment", Namespaces.CommonRole.XmlNamespace,  () => retVal.PostDeployment, ref validationResult);
                ParseElementValue(domainModelElement, "FolderPath", Namespaces.CommonRole.XmlNamespace, () => retVal.FolderPath, ref validationResult);
                ParseElementValue(domainModelElement, "PatchDeploymentFolder", Namespaces.CommonRole.XmlNamespace, () => retVal.PatchDeploymentFolder, ref validationResult);
                ParseElementValue(domainModelElement, "PatchFolderFormatStartsWith", Namespaces.CommonRole.XmlNamespace, () => retVal.PatchFolderFormatStartsWith, ref validationResult);
                ParseElementValue(domainModelElement, "UpgradeScriptName", Namespaces.CommonRole.XmlNamespace, () => retVal.UpgradeScript, ref validationResult);
                ParseElementValue(domainModelElement, "PreValidationScriptName", Namespaces.CommonRole.XmlNamespace, () => retVal.PreValidationScript, ref validationResult);
                ParseElementValue(domainModelElement, "PostValidationScriptName", Namespaces.CommonRole.XmlNamespace, () => retVal.PostValidationScript, ref validationResult);
                ParseElementValue(domainModelElement, "DetermineIfDatabaseIsAtThisPatchLevelScriptName", Namespaces.CommonRole.XmlNamespace, () => retVal.PatchLevelDeterminationScript, ref validationResult);

                ParseElementAttribute(domainModelElement, "Ignore", () => retVal.TestInfo.Ignore, ref validationResult);

                var testInfo = domainModelElement.Element("TestInfo");
                if (testInfo != null)
                {
                    retVal.TestInfo = new SqlTestInfo();
                    ParseElementAttribute(testInfo, "Ignore", () => retVal.TestInfo.Ignore, ref validationResult);
                    ParseElementAttribute(testInfo, "UserName", () => retVal.TestInfo.UserName, ref validationResult);
                    ParseElementAttribute(testInfo, "Password", () => retVal.TestInfo.Password, ref validationResult);
                    ParseElementValue(testInfo, "Sql", Namespaces.CommonRole.XmlNamespace, () => retVal.TestInfo.Sql, ref validationResult);
                }

                foreach (var elem in domainModelElement.XPathSelectElements("EnableAspnetSqlCacheDependency/OnTable"))
                {
                    retVal.EnableAspnetSqlInfo.Tables.Add(elem.Value);
                }

                ValidateDomainObject(retVal, ref validationResult, true);
            }
            catch (Exception ex)
            {
                validationResult.AddException(ex);
                return null;
            }

            return  validationResult.Result ? retVal : null;
        }

        public override IBaseRole ApplyOverrides(IBaseRole commonRole, XElement includedRole, ref ValidationResult validationResult)
        {
            var databaseDeploy = (DatabaseDeploy)base.ApplyOverrides(commonRole, includedRole, ref validationResult);

            ParseElementAttribute(includedRole, "TargetDatabase", () => databaseDeploy.TargetDatabase, ref validationResult);
            ParseElementAttribute(includedRole, "DatabaseInstance", () => databaseDeploy.DatabaseInstance, ref validationResult);

            //At this poing TargetDatabase must have been set, either in Common or as an override, so validate here.
            if(string.IsNullOrWhiteSpace(databaseDeploy.TargetDatabase))
                validationResult.AddError($"TargetDatabase is null or empty. This property must be set at the common or override level.");

            return databaseDeploy;
        }
    }
}