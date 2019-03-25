using System.ComponentModel;

namespace Deployment.Schemas
{
    /* Enum values are used to ensure loaded in correct dependency order */
    public enum SchemaNames
    {
        [Description("Deployment.Schemas.Xsd.commonroles.config.xsd")]
        CommonRoles,
        [Description("Deployment.Schemas.Xsd.deployment.config.xsd")]
        Deployment,
        [Description("Deployment.Schemas.Xsd.deploymentgroups.config.xsd")]
        DeploymentGroups,
        [Description("Deployment.Schemas.Xsd.FileIncludeInPackaging.config.xsd")]
        FileInclude,
        [Description("Deployment.Schemas.Xsd.parameters.config.xsd")]
        Parameters,
        [Description("Deployment.Schemas.Xsd.serverrole.config.xsd")]
        ServerRole,
        [Description("Deployment.Schemas.Xsd.serverroleinclude.config.xsd")]
        ServerRoleInclude,
        //[Description("Deployment.Schemas.Xsd.UniqueEnvironment.config.xsd")]
        //UniqueEnvironmentConfig,
        [Description("Deployment.Schemas.Xsd.DynamicPlaceholderMappings.config.xsd")]
        DynamicPlaceholderMappings,
        [Description("Deployment.Schemas.Xsd.RigManifest.config.xsd")]
        RigManifest,
    }
}
