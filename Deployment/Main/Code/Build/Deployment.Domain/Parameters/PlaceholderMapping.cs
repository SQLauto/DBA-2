namespace Deployment.Domain.Parameters
{
    public struct PlaceholderMapping
    {
        public PlaceholderMapping(string name, string lookup)
        {
            Name = name;
            Lookup = lookup;
        }

        public string Name { get; }
        public string Lookup { get; }
    }
}