using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Xml;
using System.Xml.Linq;
using System.Xml.Schema;
using System.Xml.XPath;
using Deployment.Common.Helpers;

namespace Deployment.Common.Xml {
    /// <summary>
    ///
    /// </summary>
    public static class XmlHelper {

        public static Tuple<bool, IList<string>> ValidateXml(IList<string> xmlSchemaFiles, string sourceXml)
        {
            XmlSchemaSet schemas = new XmlSchemaSet();
            foreach (var xmlSchemaFile in xmlSchemaFiles)
            {
                using (var reader = XmlReader.Create(xmlSchemaFile))
                {
                    schemas.Add(null, reader);
                }
            }
            return ValidateXml(schemas, sourceXml);
        }

        public static Tuple<bool, IList<string>> ValidateXml(XmlSchemaSet xmlSchemaFiles, string sourceXml)
        {
            var internalValidationErrors = new XmlSchemaValidationErrorCollection();
            ValidationEventHandler handler = (sender, args) => internalValidationErrors.Add(args);
            var settings = new XmlReaderSettings { ValidationType = ValidationType.Schema };

            try
            {
                // Set the validation settings.
                settings = new XmlReaderSettings { ValidationType = ValidationType.Schema };
                settings.ValidationFlags |= XmlSchemaValidationFlags.ProcessInlineSchema;
                settings.ValidationFlags |= XmlSchemaValidationFlags.ProcessSchemaLocation;
                settings.ValidationFlags |= XmlSchemaValidationFlags.ReportValidationWarnings;


                settings.IgnoreComments = true;
                settings.IgnoreWhitespace = true;

                settings.IgnoreProcessingInstructions = true;
                settings.ValidationEventHandler += handler;

                settings.Schemas = xmlSchemaFiles;

                if (settings.Schemas.Count == 0)
                    return new Tuple<bool, IList<string>>(false, new[] { "Missing schema file(s)."});

                // Create the XmlReader object for xml
                using (var reader = XmlReader.Create(sourceXml, settings))
                {
                    // Parse the file.
                    while (reader.Read()) { }
                }

                var validationErrors = internalValidationErrors;

                var errors = validationErrors.Select(error => error.Message).ToList();

                return new Tuple<bool, IList<string>>(errors.Count == 0, errors);
            }
            finally
            {
                settings.ValidationEventHandler -= handler;
            }
        }

        /// <summary>
        /// default XML writer settings
        /// </summary>
        public static readonly XmlWriterSettings WriterSettings = new XmlWriterSettings { Encoding = Encoding.Unicode };

        // get xml node name
        public static string RetrieveNodeFullName(XElement node) {
            var nodeName = new StringBuilder();
            CompleteNodeName(ref nodeName, node);
            return nodeName.ToString();
        }

        public static XElement CreateXElement(string markup)
        {
            var reader = XmlReader.Create(new StringReader(markup));

            var root = XElement.Load(reader);

            return root;
        }

        // complete xml node name
        private static void CompleteNodeName(ref StringBuilder nodeName, XElement node) {
            if(nodeName.Length > 0) {
                nodeName.Insert(0, "/");
            }

            nodeName.Insert(0, node.Name.LocalName);

            if(node.Parent != null) {
                CompleteNodeName(ref nodeName, node.Parent);
            }
        }

        public static bool XElementXPathExistanceTest(this XElement element, string xpathExpression)
        {
            var textReader = new StringReader(element.ToString());
            var document = new XPathDocument(textReader);
            var navigator = document.CreateNavigator();
            var node = navigator.SelectSingleNode(xpathExpression);

            return node != null;
        }

        public static bool XElementXPathExistanceTest(this XElement element, string xpathExpression, IXmlNamespaceResolver resolver)
        {
            var textReader = new StringReader(element.ToString());
            var document = new XPathDocument(textReader);
            XPathNavigator navigator = document.CreateNavigator();
            XPathNavigator node = navigator.SelectSingleNode(xpathExpression, resolver);

            return node != null;
        }

        public static string ToXml<T>(T source) where T : class
        {
            ArgumentHelper.AssertNotNull(source, "source");

            using (var memoryStream = new MemoryStream())
            {
                using (var reader = new StreamReader(memoryStream))
                {
                    var serializer = new DataContractSerializer(source.GetType());
                    serializer.WriteObject(memoryStream, source);
                    memoryStream.Position = 0;
                    return reader.ReadToEnd();
                }
            }
        }

        public static T FromXml<T>(string sourceXml, Type type) where T : class
        {
            ArgumentHelper.AssertNotNullOrEmpty(sourceXml, "sourceXml");

            var xmlSerializer = new DataContractSerializer(type);

            //using (var memoryStream = new MemoryStream())
            //{
            //    using (var writer = new StreamWriter(memoryStream))
            //    {
            //        writer.Write(sourceXml);
            //        memoryStream.Position = 0;
            //        return xmlSerializer.ReadObject(memoryStream) as T;
            //    }
            //}

            using (var stringReader = new StringReader(sourceXml))
            {
                using (var xmlReader = XmlReader.Create(stringReader, new XmlReaderSettings()))
                {
                    return xmlSerializer.ReadObject(xmlReader) as T;
                }
            }
        }

        public static string GetAttribute(this XElement element, string attribute)
        {
            XAttribute att = element.Attribute(attribute);
            return att?.Value ?? string.Empty;
        }

        public static bool GetBoolAttribute(this XElement element, string attribute, bool def)
        {
            XAttribute att = element.Attribute(attribute);
            return att == null ? def : Convert.ToBoolean(att.Value);
        }

        public static string GetElementValue(this XElement element)
        {
            return element?.Value ?? string.Empty;
        }

        public static string GetChildElementValue(this XElement element, string child)
        {
            return GetElementValue(element.Elements().FirstOrDefault(e => e.Name.LocalName == child));
        }

        public static XElement GetChildElement(this XElement element, string child)
        {
            return element.Elements().FirstOrDefault(e => e.Name.LocalName == child);
        }

        public static XElement GetChildElement(this XElement element, IList<string> children)
        {
            return element.Elements().FirstOrDefault(e => children.Contains(e.Name.LocalName));
        }

        public static bool HasChildElementNamed(this XElement element, string child)
        {
            bool hasChild = element.Elements().Any(e => e.Name.LocalName == child);
            return hasChild;
        }

        public static bool GetBoolElementValue(this XElement element, bool def)
        {
            return string.IsNullOrEmpty(element?.Value) ? def : Convert.ToBoolean(element.Value);
        }
    }
}