Param(
	[string]$RigName = 'TestSubnet',
	[int] $VMCount = 4,
	[string] $queueName = 'processed-subnet',
	[string] $storageAccountName = 'subnetmanagementstorage',
	[string] $storageAccountResourceGroupName = 'ftp-rig'
)

$exitCode = 0

Write-Host "Submitting request for subnet called $RigName with $VMCount IP Address needed"

$item = @{
    name = $RigName
	count = $VMCount 
}
[string]$RequestNewSubnetCode = 'ueth8YA0mykd7CMLP1ATRG5ugjI4SdWmXmH3A84ESyYtD/CHlMahLg=='
$url = "https://subnetmanagement.azurewebsites.net/api/RequestNewSubnet?code=$RequestNewSubnetCode"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$requestBody = ConvertTo-Json -InputObject $item
$response =  try {Invoke-RestMethod -Uri $url -Body $requestBody -ContentType "application/json" -Method Post} catch {$_.Exception.Response}

if([string]::IsNullOrEmpty($response.key)) {
    Write-Error "Failed to post Subnet request. Status Code: $($response.StatusCode)"
    Exit 1
}

$guid = $response.key
Write-Host "Subnet Request ID is $guid"

Write-Host "Connection to Processed Subnets Queue..."
$storageAccountKeys = Get-AzureRMStorageAccountKey -Name $storageAccountName -ResourceGroupName $storageAccountResourceGroupName
$storageAccountKey = $storageAccountKeys[0].Value
$storageCtx = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

[int]$Retries = 15
[int]$SecondsDelay = 5
$retryCount = 0
$completed = $false

Write-Host "Waiting 30 seconds for subnet to be processed"
Start-Sleep 30

do
{
    # Retrieve a specific queue
    $queue = Get-AzureStorageQueue –Name $queueName –Context $storageCtx
	[int]$messageCount = $queue.CloudQueue.ApproximateMessageCount

	if ($messageCount -gt 0)
	{
		Write-Verbose "Found $messageCount messages"
	
        $queueMessages = $queue.CloudQueue.GetMessages($messageCount)
		foreach($message in $queueMessages)
		{   

			$body = $message.AsString | ConvertFrom-Json
			Write-Host "Current messsage id $($body.RequestId)"
			if($body.RequestId -eq $guid)
			{
				$completed = $true
                         
                if($body.Status -eq "Created") {
                    Write-Host "Successfully created subnet $($body.Name)"
                    Write-Verbose "Request log: "
                    Write-Verbose $body.Output
                }
				elseif($body.Status -eq "Updated") {
                    Write-Host "Successfully updated subnet $($body.Name)"
                    Write-Verbose "Request log: "
                    Write-Verbose $body.Output
                }
				elseif($body.Status -eq "Found") {
                    Write-Host "Using existing subnet $($body.Name)"
                    Write-Verbose "Request log: "
                    Write-Verbose $body.Output
                }
                else {
                    $exitCode = 1
                    Write-Error "Failed to created subnet $($body.Name)"
                    Write-Error $body.Output
                }
                           
                Write-Verbose "deleting message id $($body.RequestId)"
				$queue.CloudQueue.DeleteMessage($message.Id, $message.PopReceipt)
				break
			}            
	    }	
    }
    else
    {
        if ($retryCount -ge $Retries) {
			Write-Error "Reached maximum number of $retryCount re-trys."
			$completed = $true
			$exitCode = 1
		} else {
			Write-Warning "Request not processed, checking again in $SecondsDelay seconds."
			Start-Sleep $SecondsDelay
			$retrycount++
		}
    }
}while (-not $completed)

exit $exitCode