using System;

namespace Deployment.Common
{
    [AttributeUsage(AttributeTargets.Property)]
    public sealed class MandatoryAttribute : Attribute
    {
        public MandatoryAttribute() : this(false)
        {

        }

        public MandatoryAttribute(bool allowEmptyString)
        {
            AllowEmptyString = allowEmptyString;
        }

        public bool AllowEmptyString
        {
            get;
            private set;
        }
    }
}