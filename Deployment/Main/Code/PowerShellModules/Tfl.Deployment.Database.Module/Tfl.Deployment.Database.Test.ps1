Write-Host "Testing Deployment.Database Module"

$params = @{
	ScriptPath = "D:\Testing\PatchTest.sql"
	ComputerName = $env:COMPUTERNAME
	HelperScriptsPath = "D:\HelperScriptsPath"
	TargetDatabase = "TargetDb"
	DataSource = "DataSource"
	DropFolder = "D:\Deploy\DropFolder"
	DefaultConfig = "PreProd"
	OverrideConfig = "PreProd"
	Environment = "PreProd"
}

$params1 = @{
	DataSource = "DataSource"
	DropFolder = "D:\Deploy\DropFolderxx"
	DefaultConfig = "PreProd"
	OverrideConfig = "PreProd"
	Environment = "PreProd"
}

$params2 = @{
	ScriptPath = "D:\Testing\PatchTest.sql"
	ComputerName = $env:COMPUTERNAME
	HelperScriptsPath = "D:\HelperScriptsPath\z"
	TargetDatabase = "TargetDb"
}

#$file = New-PatchScriptRunFile @params1 @params2

#if($file){
#	Write-Host $file
#}
#else{
#	Write-Warning "File Not Found"
#}

$connectionString = "Data Source=(local);Initial Catalog=SingleSignOn;Integrated Security=true"
$commandText = "set nocount on; exec dbo.[EmptyDatabase]"

#$stuff = Invoke-ExecuteNonQuery -ConnectionString $connectionString -CommandText $commandText
#$stuff = Invoke-ExecuteScalar -ConnectionString $connectionString -CommandText $commandText

Write-Host $stuff


#Get-PatchingValidation -ConnectionString $connectionString -Type "Pre"

$logData = @{EventID = "Test"
	Stuff = 1}


$xx = Invoke-LogDeploymentEvent -DeploymentLogId 1 -LogEvents $logData

Write-Host "End"