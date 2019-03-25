# ALWAYS RUN FROM THE JUMP SERVER!!!!!!
Param
(
    $MachineName = "TS-CAS1"
)

try
{
    $NPLExitCode = 0
    $NPLExitCode = Invoke-Command -ComputerName $MachineName -ScriptBlock {
        $isSuccess = 0
        try
        {
            Import-Module WebAdministration
            $name = "NPL"
            $directoryPath = "D:\NPL\WebSite\"

            # Update Authentication
            Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/AnonymousAuthentication -name enabled -value false -location $name
            Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/windowsAuthentication -name enabled -value true -location $name
            Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/basicAuthentication -name enabled -value false -location $name

            Remove-WebConfigurationProperty -PSPath IIS:\ -Location $name -filter system.webServer/security/authentication/windowsAuthentication/providers -name "."

            Add-WebConfiguration -Filter system.webServer/security/authentication/windowsAuthentication/providers -PSPath IIS:\ -Location  $name -Value NTLM
            Add-WebConfiguration -Filter system.webServer/security/authentication/windowsAuthentication/providers -PSPath IIS:\ -Location  $name -Value Negotiate

            Set-ItemProperty IIS:\Sites\$name -name physicalPath -value $directoryPath
        }
        catch [System.Exception]
        {
            $isSuccess = 1
        }

        $isSuccess
    }
} 
catch
{
	$NPLExitCode = 1;
	$errMsg = "TERMINATING: Failed to execute IIS script on Targer Server $MachineName. Exiting with code $exitCode"
	Write-Error $errMsg	    
}

$NPLExitCode