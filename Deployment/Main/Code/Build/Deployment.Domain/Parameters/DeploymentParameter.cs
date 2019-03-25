namespace Deployment.Domain.Parameters
{
    public struct DeploymentParameter
    {
        public DeploymentParameter(string text, bool encode = true, bool isLookup = false)
        {
            Text = text;
            Encode = encode;
            IsLookup = isLookup;
        }

        public string Text { get; }
        public bool Encode { get; }
        public bool IsLookup { get; }

        public override string ToString()
        {
            return string.IsNullOrEmpty(Text) ? "Not Set" : Text;
        }
    }
}