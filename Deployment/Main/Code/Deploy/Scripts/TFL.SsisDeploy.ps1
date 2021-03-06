[cmdletbinding()]
param
(
    [parameter(Mandatory=$true)][string] $ComputerName,
    [Deployment.Domain.Roles.SsisDeploy]$DeployRole
)


function Test-Output {
param([parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]$input)
	$input -and $input -eq 1
}

function Install-SsisEnvironment{
[cmdletbinding()]
param()

	$retVal = 0

	Write-Host "Setting up SSIS Environment."

	try{

		$ssisFolder = $DeployRole.Folder

		Write-Host "Determining existence of Ssis folder '$ssisFolder'"

		$query = "select case when exists(select 1 from [SSISDB].[catalog].[Folders] where Name = '$ssisFolder') then 1 else 0 end"

		$exists = ($script:connectionString | Invoke-ExecuteScalar -CommandText $query | Test-Output)

		if(!$exists){
			Write-Host "Ssis folder '$ssisFolder' was not found. Executing folder creation script."
			$output = ($script:connectionString | Invoke-ExecuteScalar -CommandText "exec [SSISDB].[catalog].[create_folder] @folder_name=N'$ssisFolder'")

			Write-Host "Setting folder description."
			$output = ($script:connectionString | Invoke-ExecuteScalar -CommandText "exec [SSISDB].[catalog].[set_folder_description] @folder_name=N'$ssisFolder', @folder_description=N'SSIS Packages for Notification Process'")
		}

		$ssisEnvironment = $DeployRole.Environment;

		Write-Host "Determining existence of Ssis environment '$ssisEnvironment'"

		$query = "select case when exists(select 1 from [SSISDB].[Catalog].[Environments] as E left join [SSISDB].[internal].[Folders] as F on E.folder_id = F.folder_id where E.name = '$ssisEnvironment' and F.name = '$ssisFolder') then 1 else 0 end"

		$exists = ($script:connectionString | Invoke-ExecuteScalar -CommandText $query) | Test-Output

		if(!$exists){
			Write-Host "Environment was not found. Creating environment '$ssisEnvironment'."
			$query = "exec [SSISDB].[catalog].[create_environment] @environment_name=N'$ssisEnvironment', @environment_description=N'Global Configuration', @folder_name=N'$ssisFolder'"
			$output = ($script:connectionString | Invoke-ExecuteScalar -CommandText $query)
		}
	}
    catch{
		Write-Host2 -Type Failure -Message "Failed to setup SSIS environment."
        Write-Error2 -ErrorRecord $_
		$retVal = 1
	}

	$retVal
}

function Invoke-Installer{
param()

	$retVal = 0

	if($DeployRole.ProjectType -ne "ISPAC" -and $DeployRole.DeploymentMode -ne "Wiz"){
		$retVal = 1
		Write-Warning "Dtutil deployments are not supported, use deployment mode WIZ to deploy ispacProjects."
		return $retVal
	}

	$ssisFolder = $DeployRole.Folder
	$projectName = $DeployRole.ProjectName
	$ssisEnvironment = $DeployRole.Environment

	try{

		Write-Host "Deploying Project '$projectName' to $dataSource (IsDeploymentWizard mode)"

		$sourcePath = Join-Path  $dropFolder $projectName
		$sourcePath = "$sourcePath.ispac"

		$command = "cmd /c isdeploymentwizard.exe /S /ST:File /SP:$sourcePath /DS:$Datasource /DP:/SSISDB/$ssisFolder/$projectName"
		Write-Host "Executing command: '$command'"

		$task = Invoke-Expression -Command $command -ErrorAction Stop

		if ($LASTEXITCODE -and $LASTEXITCODE -ne 0)
    	{
    		Write-Error "IsDeploymentWizard failed with exit code $LASTEXITCODE";
    		$retVal = 1
			return $retVal
    	}

		Write-Host "`twaiting for SSISDB to catchup";
        $complete = $script:connectionString | Wait-ForSsis -Project $projectName -Folder $ssisFolder

		if(!$complete) {
    	    Write-Host "Wait-ForSsis failed. Still no $ProjectName Project record found"
    	    $retVal = 1
        }
	}
	catch{
        Write-Host2 -Type Failure -Message "Failed to invoke SSIS installer."
		Write-Error2 -ErrorRecord $_
		$retVal = 1
	}

	$retVal
}

function Update-PackageInfo{
[cmdletbinding()]
param()

	$retVal = 0

	try{

		$ssisFolder = $DeployRole.Folder
		$projectName = $DeployRole.ProjectName
		$ssisEnvironment = $DeployRole.Environment

		Write-Host "Linking Environment to Project."

		$query = "select case when exists(select 1 from [ssisdb].[internal].[projects] as proj
				join [ssisdb].[internal].[environment_references] as ref
									on proj.project_id = ref.project_id
									where ref.environment_folder_name = N'$ssisfolder' and
											ref.environment_name = N'$ssisenvironment' and
											proj.name = N'$projectname') then 1 else 0 end"

		$exists = ($script:connectionString | Invoke-ExecuteScalar -CommandText $query | Test-Output)

		if (!$exists) {
           Write-Host "Creating Environment Reference."

	       $query = "DECLARE @reference_id BIGINT
                    EXEC [SSISDB].[catalog].[create_environment_reference]
                        @environment_name = N'$ssisEnvironment',
                    	@environment_folder_name = N'$ssisFolder',
                        @reference_id = @reference_id OUTPUT,
                    	@project_name = N'$ProjectName',
                        @folder_name = N'$ssisFolder',
                        @reference_type = A
                    SELECT @reference_id
                    GO"

			$script:connectionString | Invoke-ExecuteScalar -CommandText $query | Out-Null

		    Write-Host "`tWaiting for SSISDB to catchup";
			$complete = $script:connectionString | Wait-ForSsis -SsisEnvironment $ssisEnvironment -Folder $ssisFolder

			if(!$complete) {
    			Write-Host "Wait-ForSsis to catch up failed. Still no $ssisEnvironment Environment record found"
    			$retVal = 1
			}
		}
	}
	catch{
        Write-Error2 -ErrorRecord $_
		$retVal = 1
	}

	$retVal
}

function Update-Parameters{
[cmdletbinding()]
param()

	$retVal = 0

	if(Test-IsNullOrEmpty $DeployRole.Parameters){
		return $retVal;
	}

	$ssisFolder = $DeployRole.Folder
	$projectName = $DeployRole.ProjectName
	$ssisEnvironment = $DeployRole.Environment

	try{

		$DeployRole.Parameters | % {
			$name = $_.Name

			$result = Update-SsisParameters -ConnectionString $connectionString -SsisEnvironment $ssisEnvironment -Folder $ssisFolder -Parameter $_

			if($result){
				$DeployRole.Packages | % {
					$packageName = $_

					$complete = $connectionString | Wait-ForSsis -Package $packageName -Parameter $name

					if($complete){
						Write-Host "Package $packageName needs to be linked to $name"
						$cmdText = "EXEC [SSISDB].[catalog].[set_object_parameter_value]
									@object_type=30,
									@parameter_name = N'$name',
									@object_name = N'$packageName',
									@folder_name = N'$ssisFolder',
									@project_name = N'$ProjectName',
									@value_type = R,
									@parameter_value = N'$name'"

						$connectionString | Invoke-ExecuteNonQuery -CommandText $cmdText | Out-Null
					}
				}
			}
		}
	}
	catch{
        Write-Error2 -ErrorRecord $_
		$retVal = 1
	}

	$retVal
}

$result = 0

Write-Host ""
Write-Header "Starting role $DeployRole on $ComputerName." -AsSubHeader
$timer = [Diagnostics.Stopwatch]::StartNew()

$local = $ComputerName -in $env:computername,"localhost"

$dataSource = Get-Datasource -ComputerName $ComputerName -InstanceName $DeployRole.DatabaseInstance

Write-Host "DataSource set to '$dataSource'. Target Database is 'master'"
$connectionString = Get-ConnectionString -DataSource $dataSource -TargetDatabase "master"

try
{
	$result = Invoke-UntilFail {Install-SsisEnvironment},{Invoke-Installer},{Update-PackageInfo},{Update-Parameters}
}
catch [System.Exception]
{
	Write-Error2 -ErrorRecord $_
	$result = 1
}

$timer.Stop()
$SummaryLog | Write-Summary -Message "running role $DeployRole on $ComputerName."  -Elapsed $timer.Elapsed -ScriptResult $result
Write-Header "Ending role $DeployRole on $ComputerName" -AsSubHeader

$result