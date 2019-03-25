[cmdletbinding()]
param
(
    [parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()][string]$ComputerName,
	[parameter(Mandatory=$true)]
	[ValidateNotNull()]
	[Deployment.Domain.Roles.FileShareDeploy]$DeployRole
)

function Start-FileShareDeploy {
    [cmdletbinding()]
    param()

    $retVal = 0

    $targetPath = "\\$ComputerName\" + ($DeployRole.TargetPath -replace "$($DriveLetter):", "$DriveLetter`$")

    $share = Get-FileShare -Name $DeployRole.ShareName -ComputerName $ComputerName

    if ($DeployRole.Action -eq "Remove" ) {
        if ($share) {
            Write-Host "Removing file share $($DeployRole.ShareName)"
            Remove-FileShare -Name $DeployRole.ShareName -ComputerName $ComputerName
        }

        return $retVal
    }

    #start by getting a list of users
    $readUsers = (Get-FileShareUsers -InputObject $DeployRole -Path $accountsFile -AccessType "Read" -Password $Password) | Select-Object -ExpandProperty "QualifiedUsername"
    $changeUsers = (Get-FileShareUsers -InputObject $DeployRole -Path $accountsFile -AccessType "Change" -Password $Password) | Select-Object -ExpandProperty "QualifiedUsername"
    $fullUsers = (Get-FileShareUsers -InputObject $DeployRole -Path $accountsFile -AccessType "Full" -Password $Password) | Select-Object -ExpandProperty "QualifiedUsername"

    $shareName = $DeployRole.ShareName

    $targetPath = $DeployRole.TargetPath
    $sharePath = $targetPath.Replace("`$", ":")

    Write-Host "Path without admin share is: $sharePath"

    $func = {
        param([string]$Name, [string]$Path, [string[]]$ReadAccounts, [string[]]$ChangeAccounts, [string[]]$FullAccounts)

        $temp = @{
            'Server'   = $env:COMPUTERNAME;
            'ExitCode' = 0
        }

        Set-ExecutionPolicy Unrestricted
        Import-Module TFL.FileShare

        try {
            New-FileShare -Name $name -ComputerName $env:COMPUTERNAME -Path $path -Description "TFL File Share" -ReadAccess $readAccounts -ChangeAccess $changeAccounts -FullAccess $fullAccounts
        }
        catch {
            $temp.Error = ("An error has occured: {0}`r`n{1}" -f $_, $_.InvocationInfo.PositionMessage)
            $temp.ErrorDetail = $_
            $temp.ExitCode = 1
        }

        [PSCustomObject]$temp
    }

    if ($local) {
        $output = & $func -Name $shareName -Path $sharePath -ReadAccounts $readUsers -ChangeAccounts $changeUsers -FullAccounts $fullUsers
    }
    else {
        $output = Invoke-Command -ComputerName $ComputerName -ScriptBlock $func -ArgumentList $shareName, $sharePath, $readUsers, $changeUsers, $fullUsers
    }

    if ($output.ExitCode -ne 0) {
        if ($output.ErrorDetail) {
            Write-Error2 -ErrorRecord $output.ErrorDetail -ErrorMessage $output.Error
        }
        else {
            Write-Error2 $output.Error
        }

        Write-Host2 -Type Failure -Message "Failed to setup app pools on $ComputerName"

		return 1
    }

    $folderToTest = ("\\$ComputerName\$shareName")

    if (Test-Path $folderToTest) {
        Write-Host2 -Type Success -Message "Share has been successfully created."
    }
    else {
        Write-Host2 -Type Failure -Message "Share could not be found at $folderToTest. Make sure it has been created."
        $retVal = 1
    }

    $retVal
}

$result = 0
$local = $ComputerName -in $env:computername,"localhost"

Write-Host ""
Write-Header "Starting role $DeployRole on $ComputerName." -AsSubHeader
$timer = [Diagnostics.Stopwatch]::StartNew()

try {
	$result = Start-FileShareDeploy
}
catch [System.Exception] {
	Write-Error2 -ErrorRecord $_
	$result = 1
}

$timer.Stop()

$SummaryLog | Write-Summary -Message "running role $DeployRole on $ComputerName."  -Elapsed $timer.Elapsed -ScriptResult $result
Write-Header "Ending role $DeployRole on $ComputerName" -AsSubHeader

$result