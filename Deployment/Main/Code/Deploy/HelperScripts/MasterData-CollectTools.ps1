param
(
	[string] $DropFolder
)
function main
{
Try
{
    Write-Output "Creating Folder..."
    New-Item -Path "$DropFolder\EventReplayTools" -ItemType "Directory" -Force

    Write-Output "Copying Event Replay Tool.."
	Copy-Item -Path "$DropFolder\MasterData.EventReplayTool.exe" -Destination "$DropFolder\EventReplayTools" -Force
    Copy-Item -Path "$DropFolder\MasterData.EventReplayTool.exe.config" -Destination "$DropFolder\EventReplayTools" -Force

    Write-Output "Copying MasterData Migrate Tool..."
    Copy-Item -Path "$DropFolder\MasterData.Migrate.exe" -Destination "$DropFolder\EventReplayTools" -Force
    Copy-Item -Path "$DropFolder\MasterData.Migrate.exe.config" -Destination "$DropFolder\EventReplayTools" -Force

    Write-Output "Copying Migrate Tool.."
    Copy-Item -Path "$DropFolder\migrate.exe" -Destination "$DropFolder\EventReplayTools" -Force

	Write-Output "Copying Dependencies..."
	Copy-Item -Path "$DropFolder\Automapper.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\Elmah.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\EntityFramework.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\EntityFramework.xml" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\EntityFramework.Extended.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\EntityFramework.Extended.xml" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\EntityFramework.SqlServer.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\EntityFramework.SqlServer.xml" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\EntityFramework.MappingAPI.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\EntityFramework.BulkInsert.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\Given.Common.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\Given.Nunit.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\KellermanSoftware.Compare-Net-Objects.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\KellermanSoftware.Compare-Net-Objects.xml" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\LINQtoCSV.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\MasterData.ApplicationServices.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\MasterData.Deploy.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\MasterData.Domain.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\MasterData.Framework.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\MasterData.InfrastructureServices.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\MasterData.IntegrationTests.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\MasterData.ProcessManagers.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\MasterData.Projections.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\Newtonsoft.Json.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\NLog.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\Nlog.xml" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\NodaTime.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\NodaTime.xml" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\nunit.framework.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\nunit.framework.xml" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\StructureMap.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\StructureMap.xml" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\StructureMap.Net4.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\migrationOptions.json" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\MasterData.Migration.Infrastructure.dll" -Destination "$DropFolder\EventReplayTools" -Force
	Copy-Item -Path "$DropFolder\Data" -Destination "$DropFolder\EventReplayTools\Data" -Force -Recurse
	
    Write-Output "Copying Complete..."
}
Catch [System.Exception]
{
    $error = $_.Exception.ToString()
    Write-Error "$error"
    exit 1
}
}

main


