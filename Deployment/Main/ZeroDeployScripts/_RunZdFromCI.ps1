function WarmUpMasterDataWebApi {

write-host "Warming up the MasterData api"

try {
		$headerDictionary = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
		$headerDictionary.Add("x-api-version","1");
		$headerDictionary.Add("X-TFl-Ft-ClientName","FTP");

		$request = Invoke-WebRequest -Uri http://localhost:8734/revisions -MaximumRedirection 2 -TimeoutSec 30 -ErrorAction SilentlyContinue -Headers $headerDictionary
	}
	catch [System.Net.WebException] {
		write-host ("{0,-60} | {1,10} | {2,10} | {3,-80}" -f $url, $_.Exception.Response.StatusCode, [int]$_.Exception.Response.StatusCode, $_.Exception.Message)  -ForegroundColor "red"       
	}
	catch {
		write-host $_.Exception.Message
	}
}

function HostAllFtpComponents {

	write-host "Setting up IIS"
	start .\StartIISExpress.bat /c
		
	Start-Sleep -s 10
	
	start "http://localhost:8222"
	start "http://localhost:8080"
	start "http://localhost:8799"
    start "http://localhost:8081"
	
	Start-Sleep -s 60
	
	WarmUpMasterDataWebApi
	
	Start-Sleep -s 20
	
	start .\HostServicesInConsole.bat
	
	Start-Sleep -s 75
}


HostAllFtpComponents

