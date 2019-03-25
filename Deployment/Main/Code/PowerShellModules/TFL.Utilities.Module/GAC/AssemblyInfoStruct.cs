﻿using System.Runtime.InteropServices;

namespace TFL.Utilities.GAC
{
    [StructLayout(LayoutKind.Sequential)]
    internal struct AssemblyInfo
    {
        public int cbAssemblyInfo; // size of this structure for future expansion
        public int assemblyFlags;
        public long assemblySizeInKB;
        [MarshalAs(UnmanagedType.LPWStr)]
        public string currentAssemblyPath;
        public int cchBuf; // size of path buf.
    }
}
