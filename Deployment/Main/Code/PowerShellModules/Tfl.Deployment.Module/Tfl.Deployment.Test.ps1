$modulePath = Join-Path $PSScriptRoot "Modules"

[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
$env:PSModulePath = "$modulePath;" + $env:PSModulePath

Import-Module Tfl.Deployment -Force -ErrorAction Stop

Write-Host "Testing Deployment Module"


$func = {
	$deployment = Get-Deployment -Path "D:\Src\Deployment\Main\Code\Deploy\Scripts\Baseline.Apps.config.xml"
	Write-Host $deployment.Environment
}

& $func


#$deployment = Get-Deployment -Path "D:\Src\Deployment\Main\Code\Deploy\Scripts\Baseline.Apps.config.xml"
#Write-Host $deployment.Environment

#$deployment.Machines | fl

#$deployment.Machines | % {$_.DeploymentRoles | fl}

#$filtered = Get-Deployment -InputObject $deployment -Machines 'TS-CAS1'

#Write-Host "Filtering for machine TS-CAS1"
#$filtered.Machines | fl

##$filtered.Machines | % {$_.DeploymentRoles | fl}

##$groupFilters = Get-DeploymentGroupFilters -Groups 'Web' -Path "D:\Src\Deployment\Main\Code\Deploy\Groups\DeploymentGroups.DeploymentBaseline.xml"

##$filtered = Get-Deployment -InputObject $deployment -Groups $groupFilters

##Write-Host "Filtering for Group Web"
##$filtered.Machines | fl

##$filtered.Machines | % {$_.DeploymentRoles | fl}

#Write-Host "Getting Web deployments"
#$web = $deployment | Get-WebDeployments

#$web.Machines | fl

#$role = $web.Machines[1].DeploymentRoles[0]

#$xml = ConvertTo-DeployRoleXml $role

#Write-Host $xml

##$xml = '<WebDeploy xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><Configuration i:nil="true"/><Description>CSC External Token Status Service</Description><Groups xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays"><a:string>CASC</a:string></Groups><Include>CACC.External.TokenStatus.Service</Include><Name>TFL.WebDeploy</Name><AppPool><IdleTimeout>0</IdleTimeout><Name>CSCTokenStatusService</Name><RecycleLogEvents xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays"/><ServiceAccount>NetworkService</ServiceAccount></AppPool><AssemblyToVersionFrom>TfL.CSC.Webservice.External.TokenStatus.dll</AssemblyToVersionFrom><RegistryKey>Software\TfL\CASC\IVR</RegistryKey><Site><Application i:nil="true"/><Authentication>Basic</Authentication><DirectoryBrowsingEnabled>false</DirectoryBrowsingEnabled><Name>CSCTokenStatusService</Name><PhysicalPath>D:\tfl\CACC\CSCTokenStatusService</PhysicalPath><Port>8716</Port><VirtualDirectory i:nil="true"/></Site></WebDeploy>'

#$item = $xml | ConvertFrom-DeployRoleXml -Type Deployment.Domain.Roles.WebDeploy

#Write-Host $item

#Write-Host $item.Description

#Write-Host $item.Site

Write-Host "End"

Remove-Module Tfl.Deployment