using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using Deployment.Common.Logging;

namespace Deployment.Common.Helpers
{
    public class NetUseHelper : IDisposable
    {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct USE_INFO_2
        {
            [MarshalAs(UnmanagedType.LPWStr)]
            public string ui2_local;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string ui2_remote;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string ui2_password;
            public UInt32 ui2_status;
            public UInt32 ui2_asg_type;
            public UInt32 ui2_refcount;
            internal UInt32 ui2_usecount;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string ui2_username;
            public string ui2_domainname;
        }

        [DllImport("NetApi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        private static extern UInt32 NetUseAdd(
            [MarshalAs(UnmanagedType.LPWStr)] string uncServerName,
            UInt32 level,
            ref USE_INFO_2 buf,
            out UInt32 parmError);

        [DllImport("NetApi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        private static extern UInt32 NetUseDel(
            [MarshalAs(UnmanagedType.LPWStr)] string uncServerName,
            [MarshalAs(UnmanagedType.LPWStr)] string useName,
            UInt32 forceCond);

        [DllImport("NetApi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        private static extern UInt32 NetUseEnum(
            [MarshalAs(UnmanagedType.LPWStr)] string uncServerName,
            UInt32 level,
            ref IntPtr buf,
            UInt32 preferedMaximumSize,
            out int entriesRead,
            out int totalEntries,
            IntPtr resumeHandle);

        [DllImport("Netapi32.dll", SetLastError = true)]
        static extern int NetApiBufferFree(IntPtr buffer);
        const UInt32 UseNoforce = 0;
        const UInt32 UseForce = 1;
        const UInt32 UseLotsOfForce = 2;

        private bool _disposed;
        private int _lastError;
        private readonly IDeploymentLogger _logger;
        private IList<NetUseInfo> _currentMapped;

        public NetUseHelper(IDeploymentLogger logger)
        {
            _logger = logger;
        }

        public int LastError => _lastError;

        public bool CreateMappedDrive(string serverName, string uncPath, string device, string userName, string password, bool force = false)
        {
            var result = true;

            try
            {
                _logger?.WriteLine(
                    $"Creating mapped drive (Net Use) for {serverName} ({uncPath}).");

                var domain = userName.Split('\\')[0];
                var user = userName.Split('\\')[1];

                if (_currentMapped == null)
                    _currentMapped = GetMappedDrives();

                var found = _currentMapped.FirstOrDefault(a => a.Remote.Equals(uncPath));

                if (found != null && found.Status.Equals(NetUseStatus.Ok) && Directory.Exists(uncPath) && !force)
                {
                    _logger?.WriteLine("  Skipping Net Use as existing mapping already found.");
                    return true;
                }

                if (found != null) //clear exsiting, disconnected mappings or where it is with different credentials
                {
                    _logger?.WriteLine("  Existing mapping was found. Clearing as it is an invalid state.");
                    _logger?.WriteLine($"  Remote: {found.Remote}, Status: {found.Status}, User: {found.User}");
                    result = DeleteMappedDrive(serverName, uncPath);
                }

                if (!result)
                    return false;

                var useinfo = new USE_INFO_2
                {
                    ui2_remote = uncPath,
                    ui2_username = user,
                    ui2_domainname = domain,
                    ui2_password = password,
                    ui2_asg_type = 0,
                    ui2_usecount = 1
                };

                if (!string.IsNullOrEmpty(device))
                {
                    device = device.TrimEnd(":".ToCharArray());
                    device = device + ":";
                    useinfo.ui2_local = device;
                }

                uint paramErrorIndex;
                var returncode = NetUseAdd(null, 2, ref useinfo, out paramErrorIndex);
                _lastError = (int)returncode;

                _logger?.WriteLine($"  CreateMappedDrive complete. Exiting based on returncode {_lastError}: {returncode == 0}");

                return returncode == 0;
            }
            catch(Exception ex)
            {
                _lastError = Marshal.GetLastWin32Error();
                _logger?.WriteError(ex);
                return false;
            }
        }

        public bool CreateMappedDrive(string serverName, string serverExternalAddress, string shareName, string device, string userName, string password, bool force = false)
        {
            var uncPath = $@"\\{serverExternalAddress}\{shareName}";
            return CreateMappedDrive(serverName, uncPath, device, userName, password, force);
        }

        public bool DeleteMappedDrive(string serverName, string uncPath)
        {
            // Clear any current cached entries
            _logger?.WriteLine($"Clearing existing drive mappings for {serverName}");

            try
            {
                if (_currentMapped == null)
                    _currentMapped = GetMappedDrives();

                var found = _currentMapped.FirstOrDefault(a => a.Remote.Equals(uncPath));

                if (found == null)
                    return true;

                var returncode = NetUseDel(null, uncPath, UseLotsOfForce);
                _lastError = (int)returncode;
                _logger?.WriteLine($"Call to net use delete exited with exited code {_lastError}");
                return (returncode == 0);
            }
            catch(Exception ex)
            {
                _lastError = Marshal.GetLastWin32Error();
                _logger?.WriteError(ex);
                return false;
            }
        }

        public bool DeleteMappedDrive(string serverName, string serverExternalAddress, string shareName)
        {
            var uncPath = $@"\\{serverExternalAddress}\{shareName}";
            return DeleteMappedDrive(serverName, uncPath);
        }

        public IList<NetUseInfo> GetMappedDrives()
        {
            var buffer = IntPtr.Zero;
            int read;
            int total;
            var handle = IntPtr.Zero;

            var retVal = new List<NetUseInfo>();

            NetUseEnum(null, 2, ref buffer, 0xffffffff, out read, out total, handle);

            // now step through all network shares and check if we have already a connection to the server
            int li = 0;
            while (li < read)
            {
                var ptr = IntPtr.Add(buffer, (Marshal.SizeOf(typeof(USE_INFO_2)) * li));

                var lInfo = (USE_INFO_2)Marshal.PtrToStructure(ptr, typeof(USE_INFO_2));
                var username = lInfo.ui2_domainname + @"\" + lInfo.ui2_username;

                retVal.Add(new NetUseInfo(lInfo.ui2_remote, (NetUseStatus)lInfo.ui2_status, lInfo.ui2_remote, username));

                ++li;

                Marshal.Release(ptr);
            }

            NetApiBufferFree(buffer);

            return retVal;
        }

        public void Dispose()
        {
            if (!_disposed)
            {

            }
            _disposed = true;
            //GC.SuppressFinalize(this);
        }

        //~NetUseHelper()
        //{
        //    Dispose();
        //}
    }
}