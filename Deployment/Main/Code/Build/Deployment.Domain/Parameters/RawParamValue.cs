

namespace Deployment.Domain.Parameters
{
    public struct RawParamValue
    {
        public RawParamValue(string paramKey, bool isValid, bool isLookup)
        {
            ParameterKey = paramKey;
            IsValid = isValid;
            IsLookup = isLookup;
        }

        public string ParameterKey { get; set; }
        public bool IsValid { get; set; }
        public bool IsLookup { get; set; }
    }
}
