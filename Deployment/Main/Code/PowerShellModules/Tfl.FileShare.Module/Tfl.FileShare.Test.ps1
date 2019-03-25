Write-Host "Testing FileShare Module"

Write-Host "Testing FileShare exists"
$exists = Test-FileShare -Name "TestShare"

Write-Host "FileShare exists: $exists"

if($exists){

	Write-Host "FileShare exists. Removing"
	Remove-FileShare -Name "TestShare"
}

Write-Host "Createing FileShare"
New-FileShare -Name "TestShare" -Path "D:\TestShareFolder" -FullAccess "FAE\stevesolomon"

$exists = Test-FileShare -Name "TestShare"

Write-Host "FileShare exists: $exists"

New-FileShare -Name "TestShare" -Path "D:\TestShareFolder" -FullAccess "FAE\stevesolomon" -ReadAccess "FAE\jordanallen"

$perms = Get-FileSharePermission -Name "TestShare"

$perms | fl


if($exists){
	Write-Host "FileShare exists. Removing"
	Remove-FileShare -Name "TestShare"
}

Write-Host "End"