using System;
using System.Collections.Generic;
using System.Text;
using System.Xml.Schema;

namespace Deployment.Common.Xml
{
    public class XmlSchemaValidationErrorCollection : List<ValidationEventArgs>
    {
        internal XmlSchemaValidationErrorCollection()
        { }

        public override string ToString()
        {
            var builder = new StringBuilder();

            foreach (var validationError in this)
            {
                builder.Append("-Validation Error-");
                builder.AppendFormat("Message: {0} \r\n", validationError.Message);
                builder.AppendFormat("Severity: {0} \r\n", Enum.GetName(typeof(XmlSeverityType), validationError.Severity));
                builder.AppendFormat("Exception: {0} \r\n", validationError.Exception.GetDeepMessage());
                builder.Append("\r\n");
            }

            return base.ToString();
        }
    }
}
