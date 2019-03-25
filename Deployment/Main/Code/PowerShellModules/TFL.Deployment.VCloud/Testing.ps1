Write-Host "Starting VCloud Testing"

$vCloudUrl = 'https://vcloud.onelondon.tfl.local'
$vCloudOrg = 'ce_organisation_td'
$vCloudUser = 'zSVCCEVcloudBuild'
$vCloudPassword = ConvertTo-SecureString "P0wer5hell" -AsPlainText -Force
$RigName = "DeploymentBaseline.DevOps.RTN"

$script:vApp = Get-VApp -Name $RigName -Url $vCloudUrl -Organisation $vCloudOrg -Username $vCloudUser -Password $vCloudPassword

$isDeployed = $vApp.IsDeployed()

Write-Host "Deployed: $isDeployed"

$state = $vApp| Get-AppStatusString


Write-Host "State: $state"

#$script:vApp | Stop-VAapp