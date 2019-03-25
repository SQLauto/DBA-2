using System;

namespace Deployment.Installation
{
    /// <summary>
    /// </summary>
    [Serializable]
    public class MsiKey : IEquatable<MsiKey>
    {
        public MsiKey() : this(Guid.Empty, Guid.Empty, default(Version))
        {
        }

        public MsiKey(string upgradeCode, string productCode, Version productVersion)
        {
            ProductCode = ToGuid(productCode);
            UpgradeCode = ToGuid(upgradeCode);
            ProductVersion = productVersion;
        }

        public MsiKey(Guid upgradeCode, Guid productCode, Version productVersion)
        {
            UpgradeCode = upgradeCode;
            ProductCode = productCode;
            ProductVersion = productVersion;
        }

        public Guid UpgradeCode { get; }

        public string UpgradeCodeString => HasUpgradeCode ? ToRegistryFormatGuidString(UpgradeCode) : string.Empty;

        public Guid ProductCode { get; }
        public string ProductCodeString => HasProductCode ? ToRegistryFormatGuidString(ProductCode) : string.Empty;

        public Version ProductVersion { get; }

        public bool HasUpgradeCode => UpgradeCode != Guid.Empty;
        public bool HasProductCode => ProductCode != Guid.Empty;
        public bool HasVersion => ProductVersion != default(Version);

        public override string ToString()
        {
            return
                $"UpgradeCode: [{UpgradeCodeString}], ProductCode: [{ProductCodeString}], Version: [{ProductVersion}]";
        }

        private Guid ToGuid(string code)
        {
            Guid guid;
            var result = Guid.TryParse(code ?? string.Empty, out guid);

            return result ? guid : Guid.Empty;
        }

        private string ToRegistryFormatGuidString(Guid code)
        {
            return code.ToString("B");
        }

        public override bool Equals(object obj)
        {
            if (ReferenceEquals(null, obj)) return false;
            if (ReferenceEquals(this, obj)) return true;

            return obj.GetType() == this.GetType() && Equals((MsiKey) obj);
        }

        public bool Equals(MsiKey other)
        {
            if (ReferenceEquals(null, other)) return false;
            if (ReferenceEquals(this, other)) return true;
            return UpgradeCode.Equals(other.UpgradeCode) && ProductCode.Equals(other.ProductCode) && Equals(ProductVersion, other.ProductVersion);
        }

        public override int GetHashCode()
        {
            unchecked
            {
                var hashCode = UpgradeCode.GetHashCode();
                hashCode = (hashCode * 397) ^ ProductCode.GetHashCode();
                hashCode = (hashCode * 397) ^ (ProductVersion != null ? ProductVersion.GetHashCode() : 0);
                return hashCode;
            }
        }
    }
}
