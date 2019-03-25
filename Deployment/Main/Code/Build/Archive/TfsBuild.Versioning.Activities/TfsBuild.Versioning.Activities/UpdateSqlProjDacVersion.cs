using System;
using System.Drawing;
using System.IO;
using System.Text;
using System.Activities;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Linq;
using System.Xml;
using System.Xml.Linq;

using Microsoft.TeamFoundation.Build.Client;

// ==============================================================================================
// http://tfsversioning.codeplex.com/
//
// Author: H. Shather
// ==============================================================================================

namespace TfsBuild.Versioning.Activities
{
    [ToolboxBitmap(typeof(UpdateSqlProjDacVersion), "Resources.version.ico")]
    [BuildActivity(HostEnvironmentOption.All)]
    [BuildExtension(HostEnvironmentOption.All)]
    public sealed class UpdateSqlProjDacVersion : CodeActivity
    {
        #region Workflow Arguments

        //[RequiredArgument]
        //public InArgument<VersionTypeOptions> VersionType { get; set; }
        
        [RequiredArgument]
        public InArgument<string> ReplacementVersion { get; set; }

        [RequiredArgument]
        public InArgument<string> FilePath { get; set; }

        //[RequiredArgument]
        //public InArgument<bool> ForceCreate { get; set; }

        #endregion

        /// <summary>
        /// Update the DacVersion xml tag in a sqlproj file. If it is not there then add it
        /// </summary>
        /// <param name="context"></param>
        protected override void Execute(CodeActivityContext context)
        {
            var replacementVersion = context.GetValue(ReplacementVersion);
            var filePath = context.GetValue(FilePath);
  
            #region Validate Arguments

            if (String.IsNullOrEmpty(filePath))
            {
                throw new ArgumentException("You must provide an SqlProj file path", "FilePath");
            }

            if (String.IsNullOrEmpty(replacementVersion))
            {
                throw new ArgumentException("You must provide a new version to insert", "ReplacementVersion");
            }

            #endregion

            context.WriteBuildMessage(string.Format("Replacing DacVersion in {0} with {1}", filePath, replacementVersion), BuildMessageImportance.High);

            UpdateDacVersion(filePath, replacementVersion, context);            
        }

        /// <summary>
        /// Update the dacversion in a sqlproj file
        /// </summary>
        /// <param name="filePath"></param>
        /// <param name="replacementVersion"></param>
        /// <param name="context"></param>
        public static void UpdateDacVersion(string filePath, string replacementVersion, CodeActivityContext context)
        {
            MakeWritable(filePath);

            XElement projectElement = XElement.Load(filePath);
            bool updated = false;
            foreach (XElement propertyElement in projectElement.Elements().Where(e => e.Name.LocalName == "PropertyGroup"))
            {
                XElement dacVersionElement = (from dv in propertyElement.Elements().Where(e => e.Name.LocalName == "DacVersion") select dv).FirstOrDefault();

                if (dacVersionElement != null)
                {
                    dacVersionElement.Value = replacementVersion;
                    if (context != null)
                        context.WriteBuildMessage("Updating 'DacVersion'", BuildMessageImportance.High);
                    updated = true;
                    break;
                }
            }

            if (!updated)
            {
                // We have to add this in ourselves
                if (context != null)
                    context.WriteBuildMessage("'DacVersion' not found, adding it ourselves", BuildMessageImportance.High);

                XElement propertyElement = projectElement.Elements().Where(e => e.Name.LocalName == "PropertyGroup").FirstOrDefault();
                if (propertyElement != null)
                {
                    XNamespace ns =  propertyElement.GetDefaultNamespace();
                    propertyElement.Add(new XElement(ns + "DacVersion", replacementVersion));
                }

            }

            XDocument document = new XDocument();
            document.Add(projectElement);
            document.Save(filePath);
        }

        /// <summary>
        /// Make a file writable
        /// </summary>
        /// <param name="file"></param>
        private static void MakeWritable(string file)
        {
            FileInfo fileInfo = new FileInfo(file);
            if (fileInfo.IsReadOnly)
                fileInfo.IsReadOnly = false;
        }
    }
}
