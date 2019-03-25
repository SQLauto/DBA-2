$title = "Set ZeroDeployPath env var"
$sharedZeroDeployPath = "D:\Autogration\Shared\Components"
$userZeroDeployPath = "D:\Autogration\"+$env:USERNAME+"\Components"
$message = "Do you want to set the path to the default shared location?`n`nShared - $sharedZeroDeployPath`nUser - $userZeroDeployPath`n`n"


$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Shared", `
    "Sets ZeroDeployPath to $sharedZeroDeployPath"

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&User", `
    "Sets ZeroDeployPath to  $userZeroDeployPath"

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($result)
    {
        0 {
            Write-Host "Setting %ZeroDeployPath% to $sharedZeroDeployPath"
            [Environment]::SetEnvironmentVariable("ZeroDeployPath",$null,"User")
            [Environment]::SetEnvironmentVariable("ZeroDeployPath", $sharedZeroDeployPath, "Machine")
        }
        1 {
            Write-Host "Setting %ZeroDpeloyPath% to $userZeroDeployPath"
            [Environment]::SetEnvironmentVariable("ZeroDeployPath",$null,"Machine")
            [Environment]::SetEnvironmentVariable("ZeroDeployPath", $userZeroDeployPath, "User")
        }
    }

