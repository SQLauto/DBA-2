namespace Deployment.Common
{
    internal static class Win32ErrorCodes
    {
        internal const int Ok = 0x000;
        internal const int NERR_Success = 0x000;
        internal const int AccessDenied = 0x005;
        internal const int InvalidHandle = 0x006;
        internal const int InvalidParameter = 0x057;
        internal const int InsufficientBuffer = 0x07A;
        internal const int AlreadyExists = 0x0B7;
        internal const int NoMoreItems = 0x103;
        internal const int InvalidFlags = 0x3EC;
        internal const int ServiceMarkedForDelete = 0x430;
        internal const int NoneMapped = 0x534;
        internal const int MemberNotInAlias = 0x561;
        internal const int MemberInAlias = 0x562;
        internal const int NoSuchMember = 0x56B;
        internal const int InvalidMember = 0x56C;
        internal const int NERR_GroupNotFound = 0x8AC;
    }
}