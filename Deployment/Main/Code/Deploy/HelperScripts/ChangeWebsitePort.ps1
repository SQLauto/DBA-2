
$cred = Get-Credential -Credential FAELAB\tfsbuild

Invoke-Command -ComputerName TS-CAS1 -Credential $cred -ScriptBlock { 
	Import-Module webadministration; 
	Set-WebConfigurationProperty "/system.applicationHost/sites/site[@name='Default Web Site']/bindings/binding[@protocol='http']" -name bindingInformation -value '*:443:'
	}