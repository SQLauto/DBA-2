$taskName = "PaymentAssuranceTask"
$script =  "-ExecutionPolicy Bypass -file D:\wwwroot\execplan\myscripts\sql2excel\sql2excel.ps1"
$action = New-ScheduledTaskAction –Execute "powershell.exe" -Argument  "$script"
$trigger = New-ScheduledTaskTrigger -Once -At "26 November 2018 12:22:30"
#$trigger = New-ScheduledTaskTrigger -Daily -At 3am

$Description="Payment Assurance Task"
$msg = "Enter the username and password that will run the task"; 
$credential = $Host.UI.PromptForCredential("Task username and password",$msg,"$env:userdomain\$env:username",$env:userdomain)
$username = $credential.UserName
$password = $credential.GetNetworkCredential().Password
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd #-DeleteExpiredTaskAfter 00:00:01

$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like $taskName }

if($taskExists) 
{
   Unregister-ScheduledTask $taskName -Confirm:$false
} 
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest  -Settings $settings -Description $Description -User $username -Password $password
