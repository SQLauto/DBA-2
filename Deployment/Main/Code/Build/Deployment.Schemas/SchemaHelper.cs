using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Xml;
using System.Xml.Schema;
using Deployment.Common;

namespace Deployment.Schemas
{
    public static class SchemaHelper
    {
        /*
         * Internally this throws and catches exceptions which makes debugging this solution generally annoying
         * the attribute [DebuggerHidden] stops the debugger from seeing the exception and debugging this method in general.
         */
        [DebuggerHidden]
        public static XmlSchemaSet GetDeploymentSchemas(params SchemaNames[] schemaFiles)
        {
            Assembly assembly = Assembly.GetExecutingAssembly();

            XmlSchemaSet schemas = new XmlSchemaSet();
            foreach (var schemaFile in schemaFiles)
            {
                string schemaFileName = schemaFile.Description();
                Stream xmlStream = assembly.GetManifestResourceStream(schemaFileName);
                
                var reader = XmlReader.Create(xmlStream);
                schemas.Add(null, reader);
            }

            return schemas;
        }

        /*
       * Internally this throws and catches exceptions which makes debugging this solution generally annoying
       * the attribute [DebuggerHidden] stops the debugger from seeing the exception and debugging this method in general.
       */
        [DebuggerHidden]
        public static XmlSchemaSet GetDeploymentSchemas()
        {
            return GetDeploymentSchemas(
                SchemaNames.CommonRoles,
                SchemaNames.Deployment,
                SchemaNames.DeploymentGroups,
                SchemaNames.FileInclude,
                SchemaNames.Parameters,
                SchemaNames.ServerRole,
                SchemaNames.ServerRoleInclude
                );
        }
    }
}