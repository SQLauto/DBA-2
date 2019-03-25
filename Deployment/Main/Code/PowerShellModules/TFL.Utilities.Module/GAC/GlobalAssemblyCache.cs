﻿using System;
using System.Collections.Generic;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;

namespace TFL.Utilities.GAC
{
    public static class GlobalAssemblyCache
    {
        public static IEnumerable<AssemblyName> GetAssemblies()
        {
            IAssemblyEnum assemblyEnum;
            ComCheck(FusionApi.CreateAssemblyEnum(out assemblyEnum, IntPtr.Zero, null, AssemblyCacheFlags.Gac, IntPtr.Zero));

            IAssemblyName fusionAssemblyName;
            do
            {
                ComCheck(assemblyEnum.GetNextAssembly(IntPtr.Zero, out fusionAssemblyName, 0));
                if (fusionAssemblyName != null)
                {
                    yield return new AssemblyName(GetDisplayName(fusionAssemblyName));
                }
            } while (fusionAssemblyName != null);
        }

        public static string GetAssemblyCacheClr2Path()
        {
            int bufferSize = 512;
            var buffer = new StringBuilder(bufferSize);

            int hResult = FusionApi.GetCachePath(AssemblyCacheFlags.Root, buffer, ref bufferSize);
            if ((uint)hResult == 0x8007007A)  // ERROR_INSUFFICIENT_BUFFER
            {
                buffer = new StringBuilder(bufferSize);
                ComCheck(FusionApi.GetCachePath(AssemblyCacheFlags.Root, buffer, ref bufferSize));
            }
            else
            {
                ComCheck(hResult);
            }

            return buffer.ToString();
        }

        public static string GetAssemblyCacheClr4Path()
        {
            int bufferSize = 512;
            var buffer = new StringBuilder(bufferSize);

            int hResult = FusionApi.GetCachePath(AssemblyCacheFlags.RootEx, buffer, ref bufferSize);
            if ((uint)hResult == 0x8007007A)  // ERROR_INSUFFICIENT_BUFFER
            {
                buffer = new StringBuilder(bufferSize);
                ComCheck(FusionApi.GetCachePath(AssemblyCacheFlags.RootEx, buffer, ref bufferSize));
            }
            else
            {
                ComCheck(hResult);
            }

            return buffer.ToString();
        }

        public static void InstallAssembly(string path, InstallReference reference, bool force)
        {
            if (path == null)
            {
                throw new ArgumentNullException(nameof(path));
            }

            var flags = force ? AssemblyCommitFlags.ForceRefresh : AssemblyCommitFlags.Refresh;

            FusionInstallReference fusionReference = null;
            if (reference != null)
            {
                if (!reference.CanBeUsed())
                {
                    throw new ArgumentException("InstallReferenceType can not be used", nameof(reference));
                }

                fusionReference = new FusionInstallReference(reference.Type, reference.Identifier, reference.Description);
            }

            var assemblyCache = GetAssemblyCache();

            ComCheck(assemblyCache.InstallAssembly((int)flags, path, fusionReference));
        }

        public static UninstallResult UninstallAssembly(AssemblyName assemblyName, InstallReference reference)
        {
            if (assemblyName == null)
            {
                throw new ArgumentNullException(nameof(assemblyName));
            }
            if (!assemblyName.IsFullyQualified())
            {
                throw new ArgumentOutOfRangeException(nameof(assemblyName), assemblyName, "Must be a fully qualified assembly name");
            }

            FusionInstallReference fusionReference = null;
            if (reference != null)
            {
                if (!reference.CanBeUsed())
                {
                    throw new ArgumentException("InstallReferenceType can not be used", nameof(reference));
                }

                fusionReference = new FusionInstallReference(reference.Type, reference.Identifier, reference.Description);
            }

            var assemblyCache = GetAssemblyCache();

            var disposition = AssemblyCacheUninstallDisposition.Uninstalled;
            ComCheck(assemblyCache.UninstallAssembly(0, assemblyName.GetFullyQualifiedName(), fusionReference, out disposition));

            return (UninstallResult)disposition;
        }

        public static IEnumerable<InstallReference> GetInstallReferences(AssemblyName assemblyName)
        {
            IAssemblyName fusionAssemblyName;
            ComCheck(FusionApi.CreateAssemblyNameObject(out fusionAssemblyName, assemblyName.GetFullyQualifiedName(), CreateAssemblyNameObjectFlags.ParseDisplayName, IntPtr.Zero));

            IInstallReferenceEnum installReferenceEnum;
            ComCheck(FusionApi.CreateInstallReferenceEnum(out installReferenceEnum, fusionAssemblyName, 0, IntPtr.Zero));

            do
            {
                IInstallReferenceItem item;
                int hResult = installReferenceEnum.GetNextInstallReferenceItem(out item, 0, IntPtr.Zero);
                if ((uint)hResult == 0x80070103)  // ERROR_NO_MORE_ITEMS
                {
                    yield break;
                }
                ComCheck(hResult);

                IntPtr refData;
                ComCheck(item.GetReference(out refData, 0, IntPtr.Zero));

                var fusionReference = new FusionInstallReference();
                Marshal.PtrToStructure(refData, fusionReference);

                var reference = new InstallReference(InstallReferenceGuid.ToType(fusionReference.GuidScheme), fusionReference.Identifier,
                    fusionReference.NonCanonicalData);

                yield return reference;
            } while (true);
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Security", "CA2122:DoNotIndirectlyExposeMethodsWithLinkDemands")]
        public static string GetAssemblyPath(AssemblyName assemblyName)
        {
            if (assemblyName == null)
            {
                throw new ArgumentNullException(nameof(assemblyName));
            }
            if (!assemblyName.IsFullyQualified())
            {
                throw new ArgumentOutOfRangeException(nameof(assemblyName), assemblyName, "Must be a fully qualified assembly name");
            }

            var assemblyCache = GetAssemblyCache();

            AssemblyInfo info = new AssemblyInfo
            {
                cbAssemblyInfo = Marshal.SizeOf(typeof(AssemblyInfo)),
                cchBuf = 1024
            };
            info.currentAssemblyPath = new string('\0', info.cchBuf);

            int hResult = assemblyCache.QueryAssemblyInfo(QueryAssemblyInfoFlags.Default, assemblyName.GetFullyQualifiedName(), ref info);
            if ((uint)hResult == 0x8007007A)  // ERROR_INSUFFICIENT_BUFFER
            {
                info.currentAssemblyPath = new string('\0', info.cchBuf);
                ComCheck(assemblyCache.QueryAssemblyInfo(QueryAssemblyInfoFlags.Default, assemblyName.GetFullyQualifiedName(), ref info));
            }
            else
            {
                ComCheck(hResult);
            }

            return info.currentAssemblyPath;
        }

        public static string GetFullyQualifiedAssemblyName(AssemblyName assemblyName)
        {
            return assemblyName.GetFullyQualifiedName();
        }

        public static bool IsFullyQualifiedAssemblyName(AssemblyName assemblyName)
        {
            return assemblyName.IsFullyQualified();
        }

        private static string GetDisplayName(IAssemblyName assemblyName)
        {
            int bufferSize = 1024;
            var buffer = new StringBuilder(bufferSize);

            int hResult = assemblyName.GetDisplayName(buffer, ref bufferSize, AssemblyNameDisplayFlags.Full);
            if ((uint)hResult == 0x8007007A)  // ERROR_INSUFFICIENT_BUFFER
            {
                buffer = new StringBuilder(bufferSize);
                ComCheck(assemblyName.GetDisplayName(buffer, ref bufferSize, AssemblyNameDisplayFlags.Full));
            }
            else
            {
                ComCheck(hResult);
            }

            return buffer.ToString();
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Security", "CA2122:DoNotIndirectlyExposeMethodsWithLinkDemands")]
        private static int ComCheck(int hResult)
        {
            if (hResult != 0) // S_OK
            {
                Marshal.ThrowExceptionForHR(hResult);
            }

            return hResult;
        }

        private static IAssemblyCache GetAssemblyCache()
        {
            IAssemblyCache assemblyCache = null;
            ComCheck(FusionApi.CreateAssemblyCache(out assemblyCache, 0));
            return assemblyCache;
        }
    }
}
