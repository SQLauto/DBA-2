Param
(
    $TargetMachine,
    $AppPoolName,
	$AppPoolIdentityType,
    $AppPoolServiceAccount,
    $AppPoolTimeout,
    $AppPoolEventLogRecycle
)

function Invoke-Main {
param()

	$func = {
        param($AppPoolName, $AppPoolIdentityType, $AppPoolServiceAccount, $AppPoolTimeout, $AppPoolEventLogRecycle)
        $retVal = 0

		try {
            Import-Module WebAdministration

            $AppPool = Get-Item "IIS://AppPools/$AppPoolName"

			Write-Host "AppPool identity type is set to $($AppPool.ProcessModel.IdentityType)"

			if($AppPool.ProcessModel.IdentityType -eq $AppPoolIdentityType)
			{
				if($AppPoolIdentityType -eq "SpecificUser")
				{
					Write-Host "Testing service account identity."
					if($AppPool.ProcessModel.userName -ne $AppPoolServiceAccount)
					{
						$retVal = 1
						Write-Host "User $AppPoolServiceAccount does not match" $AppPool.ProcessModel.userName
					}
				}
			}
			else
			{
				$retVal = 5
				Write-Host "IdentityType $AppPoolIdentityType does not match" $AppPool.ProcessModel.IdentityType
			}

            if($AppPoolTimeout -ne $null)
            {
                Write-Host "Testing app pool timeout."
				if($AppPool.ProcessModel.IdleTimeout.Minutes -ne $AppPoolTimeout)
                {
                    $retVal = 2
                    Write-Host "Timeout $AppPoolTimeout does not match" $AppPool.ProcessModel.IdleTimeout.Minutes
                }
            }

            if($AppPoolEventLogRecycle -ne $null)
            {
                Write-Host "Testing recyle events."
				if($AppPool.Recycling.LogEventOnRecycle -ne $AppPoolEventLogRecycle)
                {
                    $retVal = 3
                    Write-Host "Event Details $AppPoolEventLogRecycle does not match" $AppPool.Recycling.LogEventOnRecycle
                }
            }
        }
        catch
        {
            $retVal = 4
        }

		$retVal
	}


	try{
		#TODO: Change this to distinguish between local and non-local
		$sessions = New-PSSession -ComputerName $TargetMachine
		$output = Invoke-Command -Session $sessions -ScriptBlock $func -ArgumentList $AppPoolName,$AppPoolIdentityType,$AppPoolServiceAccount,$AppPoolTimeout,$AppPoolEventLogRecycle
	}
	finally{
		Remove-PSSession $sessions -ErrorAction Continue
	}

	$output
}

$exitCode = 0

try{
	$exitCode = Invoke-Main
}
catch{
	Write-Error2 -ErrorRecord $_
	$exitCode = 1
}

exit $exitCode