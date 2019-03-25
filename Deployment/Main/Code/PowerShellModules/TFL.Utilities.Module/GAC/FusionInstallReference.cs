using System;
using System.Runtime.InteropServices;

namespace TFL.Utilities.GAC
{
    [StructLayout(LayoutKind.Sequential)]
    internal class FusionInstallReference
    {
        public FusionInstallReference()
            : this(Guid.Empty, null, null)
        {
        }

        public FusionInstallReference(InstallReferenceType type, string identifier, string nonCanonicalData)
            : this(InstallReferenceGuid.FromType(type), identifier, nonCanonicalData)
        {
        }

        public FusionInstallReference(Guid guidScheme, string identifier, string nonCanonicalData)
        {
            int idLength = identifier?.Length ?? 0;
            int dataLength = nonCanonicalData?.Length ?? 0;

            cbSize = (int)(2 * IntPtr.Size + 16 + (idLength + dataLength) * 2);
            flags = 0;
            // quiet compiler warning
            if (flags == 0) { }
            this.guidScheme = guidScheme;
            this.identifier = identifier;
            this.nonCanonicalData = nonCanonicalData;
        }

        public Guid GuidScheme => guidScheme;

        public string Identifier => identifier;

        public string NonCanonicalData => nonCanonicalData;

        int cbSize;
        int flags;
        readonly Guid guidScheme;
        [MarshalAs(UnmanagedType.LPWStr)] readonly string identifier;
        [MarshalAs(UnmanagedType.LPWStr)] readonly string nonCanonicalData;
    }
}
