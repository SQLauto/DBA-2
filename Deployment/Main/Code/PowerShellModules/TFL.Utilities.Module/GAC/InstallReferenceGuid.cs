using System;

namespace TFL.Utilities.GAC
{
    internal static class InstallReferenceGuid
    {
        public static Guid UninstallSubkeyGuid { get; } = new Guid("8cedc215-ac4b-488b-93c0-a50a49cb2fb8");
        public static Guid FilePathGuid { get; } = new Guid("b02f9d65-fb77-4f7a-afa5-b391309f11c9");
        public static Guid OpaqueGuid { get; } = new Guid("2ec93463-b0c3-45e1-8364-327e96aea856");
        public static Guid MsiGuid { get; } = new Guid("25df0fc1-7f97-4070-add7-4b13bbfd7cb8");
        public static Guid OsInstallGuid { get; } = new Guid("d16d444c-56d8-11d5-882d-0080c847b195");

        public static Guid FromType(InstallReferenceType type)
        {
            switch (type)
            {
                case InstallReferenceType.WindowsInstaller:
                    return MsiGuid;
                case InstallReferenceType.Installer:
                    return UninstallSubkeyGuid;
                case InstallReferenceType.FilePath:
                    return FilePathGuid;
                case InstallReferenceType.Opaque:
                    return OpaqueGuid;
                case InstallReferenceType.OsInstall:
                    return OsInstallGuid;
                default:
                    throw new InvalidOperationException($"Unknown InstallReferencGuid for {type}");
            }
        }

        public static InstallReferenceType ToType(Guid guid)
        {
            if (guid == MsiGuid)
                return InstallReferenceType.WindowsInstaller;
            if (guid == UninstallSubkeyGuid)
                return InstallReferenceType.Installer;
            if (guid == FilePathGuid)
                return InstallReferenceType.FilePath;
            if (guid == OpaqueGuid)
                return InstallReferenceType.Opaque;
            if (guid == OsInstallGuid)
                return InstallReferenceType.OsInstall;

            throw new InvalidOperationException($"Unknown InstallReferencType for {guid}");
        }
    }
}
