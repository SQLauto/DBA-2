filter Format-OutputColor {
    param(
        [Hashtable]$WordLookup = $null
    )

	$default = @{Red = @('Stopped','Error','Offline','Disabled','Failed'); Green=@('Running','Started','Online','Enabled'); Yellow = @('Stopping','Starting')}

	$lookup = Join-Hashtables $default $WordLookup

	$all = $_

	$lines = ($all -split '\r\n')

	$lines | ForEach-Object {
		$line = $_

		$lookup.GetEnumerator() | ForEach-Object {
			$color = $_.Name

			$_.value | ForEach-Object {
			$word = $_
			$index = $line.IndexOf($word, [System.StringComparison]::InvariantCultureIgnoreCase)

				while($index -ge 0){
					Write-Host $line.Substring(0,$index) -NoNewline
					Write-Host $line.Substring($index, $word.Length) -NoNewline -ForegroundColor $color
					$used =$word.Length + $index
					$remain = $line.Length - $used
					$line =$line.Substring($used, $remain)
					$index = $line.IndexOf($word, [System.StringComparison]::InvariantCultureIgnoreCase)
				}
			}
		}

		Write-Host $line
	}
}

function Join-Hashtables {
[CmdletBinding()]
Param
(   [Parameter(Mandatory=$true)]
    [Hashtable]$First,
    [Hashtable]$Second = $null
)

    function Set-Keys ($First, $Second)
    {
        @($First.Keys) | Where-Object {
            $Second.ContainsKey($_)
        } | ForEach-Object {
            if (($First.$_ -is [Hashtable]) -and ($Second.$_ -is [Hashtable])) {
                Set-Keys -First $First.$_ -Second $Second.$_
            }
            else {
                $First.Remove($_)
                $First.Add($_, $Second.$_)
            }
        }
    }

    function Add-Keys ($First, $Second)
    {
        @($Second.Keys) | ForEach-Object {
            if ($First.ContainsKey($_))
            {
                if (($Second.$_ -is [Hashtable]) -and ($First.$_ -is [Hashtable]))
                {
                    Add-Keys -First $First.$_ -Second $Second.$_
                }
            }
            else
            {
                $First.Add($_, $Second.$_)
            }
        }
    }

	if(!$Second){
		return  $First.Clone()
	}

    # Do not touch the original hashtables
    $firstClone  = $First.Clone()
    $secondClone = $Second.Clone()

    # Bring modified keys from secondClone to firstClone
    Set-Keys -First $firstClone -Second $secondClone

    # Bring additional keys from secondClone to firstClone
    Add-Keys -First $firstClone -Second $secondClone

    # return firstClone
    $firstClone
}

function Get-WindowsServiceStatus {
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true)] [string[]]$ComputerName,
	[Parameter(Mandatory=$true)] [string[]]$Service
	)
	PROCESS{

		$func =
		{
			param([string[]]$services)

			function Execute
			{
				$temp = @{
					'Server' = $env:COMPUTERNAME
					'Clustered' = $false
					'ExitCode' = 0
				}

				try{
					$temp.Services = Get-WmiObject win32_Service | % {
							New-Object -TypeName PSObject -Property @{ Status=$_.State; Name=$_.Name; DisplayName=$_.DisplayName; StartMode=$_.StartMode }
						} | ? { $services -contains $_.Name }
				}
				catch{
					$temp.ExitCode = 1
					$temp.Error = "Error accessing the services on server"
					$temp.ErrorDetail = $_
				}

				[pscustomobject]$temp
			}

			Execute
		}

		$server = $ComputerName[0]

		if ($ComputerName -eq $env:COMPUTERNAME) {
			$output = & $func -Services $Service
		}
		else {
			try{
				$sessions = $ComputerName | New-PSsession
				$output = Invoke-Command -Session $sessions -ScriptBlock $func -ArgumentList (,$Service)
			}
			finally{
				Remove-PSSession $sessions -ErrorAction Continue
			}
		}

		$output
	}
}

$logFile1 = Register-LogFile -Path TableOutputTesting.log -WithHeader

Write-Host "Writing with native Write-Host"
Write-Warning "This is a warning"

$output = Get-WindowsServiceStatus $env:COMPUTERNAME @('EventLog', 'lmhosts') | Sort-Object -Property Server

$output | Select-Object -ExpandProperty Services Server | Format-Table Name, Status, StartMode, DisplayName -GroupBy Server -auto | Out-String -Stream | Format-OutputColor

Write-Host "Logging to console"
Write-Host2 -Type Success

$logFile1 | Unregister-LogFile