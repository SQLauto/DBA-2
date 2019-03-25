# A) Copy Files onto AD box to D:\Powershell5
# 	 Files you need are: 
#		1) This one
#		2) PendingReboot
#		3) InstallPowershell5.ps1
#		4) Win7AndW2K8R2-KB3134760-x64.msu (\\FTDC2DFS001\Media\Powershell\PowerShell5\)
# B) Create a share of D:\Powershell5 with access for all on the AD Box, such that the resulting share is: \\FAEADG001\PowerShell5
# NOTE): If Powershell installs but does not run verify that .NET 4.5.2 is installed as to run it requires this but is not an installation pre-req!


.\InstallPowershell5.ps1 -TargetMachine "TS-CAS1", "TS-CIS1", "TS-DB1", "TS-DB2", "TS-FAE1", "TS-FAE2", "TS-FAE3", "TS-FAE4", "TS-FTM1", "TS-PARE1", "TS-SAS1", "TS-OYBO1" -Installer "\\FAEADG001\PowerShell5\Win7AndW2K8R2-KB3134760-x64.msu" -Username "faelab\tfsbuild" -Password "LMTF`$Bu1ld" > "PowerShell5Install.txt"
