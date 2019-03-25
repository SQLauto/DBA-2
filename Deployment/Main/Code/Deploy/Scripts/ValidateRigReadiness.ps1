#$retval = 0
	
try
{
    Push-Location (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent)

    $file =  Get-ChildItem . | Where-Object {$_.Name -eq 'Rigmanifest.xml'}

    if($file)
    {
        Write-Host "Rigmanifest.xml file found."
        [xml]$xml = Get-Content $file
        $vmList = @()
        $xml.machines.machine | Where-Object {$_.name -ne ""} | ForEach-Object {
            $vmList += $_.ipv4address
        }
        
        Write-Host "Total Initial count $($vmList.Count)"
        $loopCount = 0			
		Do{
            Start-Sleep -Seconds 30
            foreach($vm in $vmList)
            {
                Write-Host "Testing $vm"
                $success = Test-Connection $vm -Count 1 -ErrorAction SilentlyContinue
                if($success)
                {
                    Write-Host "Found $vm" -ForegroundColor Green
                    $vmList = $vmList | Where-Object {$_ -ne $vm}
                }
            }                
        }While($loopCount -lt 10 -and $vmList.Count -gt 0)

        Write-Host "Total final count $($vmList.Count)"

        #if($vmList.Count -gt 0)
        #{
        #    $retval = 1
        #}
    }
}finally{
    Pop-Location
}

#return $retval