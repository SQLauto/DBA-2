[CmdletBinding(PositionalBinding=$True)]
Param(
    [Parameter(Mandatory = $true)]
    [String]$Path,                                           # required    needs to be alphanumeric    
    [Int]$AutoDeleteOnIdle = -1,                             # optional    default to -1
    [Int]$DefaultMessageTimeToLive = -1,                     # optional    default to -1
    [Int]$DuplicateDetectionHistoryTimeWindow = 10,          # optional    default to 10
    [Bool]$EnableBatchedOperations = $True,                  # optional    default to true
    [Bool]$EnableFilteringMessagesBeforePublishing = $False, # optional    default to false
    [Bool]$EnableExpress = $False,                           # optional    default to false
    [Bool]$EnablePartitioning = $False,                      # optional    default to false
    [Bool]$IsAnonymousAccessible = $False,                   # optional    default to false
    [Int]$MaxSizeInMegabytes = 1024,                         # optional    default to 1024
    [Bool]$RequiresDuplicateDetection = $False,              # optional    default to false
    [Bool]$SupportOrdering = $True,                          # optional    default to true
    [String]$UserMetadata = $Null,                           # optional    default to null
    [Parameter(Mandatory = $true)]
    [ValidatePattern("^[a-z0-9]*$")]
    [String]$Namespace,                                      # required    needs to be alphanumeric
    [Bool]$CreateACSNamespace = $False,                      # optional    default to $false
    [String]$Location = "West Europe"                        # optional    default to "West Europe"
    )

# Set the output level to verbose and make the script stop on error
$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

# Mark the start time of the script execution
$startTime = Get-Date

# Create Azure Service Bus namespace
$CurrentNamespace = Get-SBNamespace -Name $Namespace


# Check if the namespace already exists or needs to be created
if ($CurrentNamespace)
{
    Write-Output "The namespace [$Namespace] already exists in the [$($CurrentNamespace.Region)] region." 
}
else
{
    Write-Host "The [$Namespace] namespace does not exist."
    Write-Output "Creating the [$Namespace] namespace in the [$Location] region..."
    New-SBNamespace -Name $Namespace -Location $Location -CreateACSNamespace $CreateACSNamespace -NamespaceType Messaging
    $CurrentNamespace = Get-SBNamespace -Name $Namespace
    Write-Host "The [$Namespace] namespace in the [$Location] region has been successfully created."
}

$sbr = Get-SBAuthorizationRule -Namespace $Namespace

# Create the NamespaceManager object to create the topic
Write-Host "Creating a NamespaceManager object for the [$Namespace] namespace..."
$NamespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($sbr.ConnectionString);
Write-Host "NamespaceManager object for the [$Namespace] namespace has been successfully created."

# Check if the topic already exists
if ($NamespaceManager.TopicExists($Path))
{
    Write-Output "The [$Path] topic already exists in the [$Namespace] namespace." 
}
else
{
    Write-Output "Creating the [$Path] topic in the [$Namespace] namespace..."
    $TopicDescription = New-Object -TypeName Microsoft.ServiceBus.Messaging.TopicDescription -ArgumentList $Path
    #if ($AutoDeleteOnIdle -ge 5)
    #{
    #    $TopicDescription.AutoDeleteOnIdle = [System.TimeSpan]::FromMinutes($AutoDeleteOnIdle)
    #}
    if ($DefaultMessageTimeToLive -gt 0)
    {
        $TopicDescription.DefaultMessageTimeToLive = [System.TimeSpan]::FromMinutes($DefaultMessageTimeToLive)
    }
    if ($DuplicateDetectionHistoryTimeWindow -gt 0)
    {
        $TopicDescription.DuplicateDetectionHistoryTimeWindow = [System.TimeSpan]::FromMinutes($DuplicateDetectionHistoryTimeWindow)
    }
    $TopicDescription.EnableBatchedOperations = $EnableBatchedOperations
   # $TopicDescription.EnableExpress = $EnableExpress
    $TopicDescription.EnableFilteringMessagesBeforePublishing = $EnableFilteringMessagesBeforePublishing
    $TopicDescription.EnablePartitioning = $EnablePartitioning
    $TopicDescription.IsAnonymousAccessible = $IsAnonymousAccessible
    $TopicDescription.MaxSizeInMegabytes = $MaxSizeInMegabytes
    $TopicDescription.RequiresDuplicateDetection = $RequiresDuplicateDetection
    if ($EnablePartitioning)
    {
        $TopicDescription.SupportOrdering = $False
    }
    else
    {
        $TopicDescription.SupportOrdering = $SupportOrdering
    }
    $TopicDescription.UserMetadata = $UserMetadata
    $NamespaceManager.CreateTopic($TopicDescription);
    Write-Host "The [$Path] topic in the [$Namespace] namespace has been successfully created."
}

# Mark the finish time of the script execution
$finishTime = Get-Date

# Output the time consumed in seconds
$TotalTime = ($finishTime - $startTime).TotalSeconds
Write-Output "The script completed in $TotalTime seconds."