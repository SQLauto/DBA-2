[CmdletBinding(PositionalBinding=$True)]
Param(
    [Parameter(Mandatory = $true)]
    [String]$TopicPath,                                              # required    needs to be alphanumeric
    [Parameter(Mandatory = $true)]
    [String]$Name,                                                   # required    needs to be alphanumeric    
    [Int]$AutoDeleteOnIdle = -1,                                     # optional    default to -1
    [Int]$DefaultMessageTimeToLive = -1,                             # optional    default to -1
    [Bool]$EnableBatchedOperations = $True,                          # optional    default to true
    [Bool]$EnableDeadLetteringOnFilterEvaluationExceptions = $True,  # optional    default to true
    [Bool]$EnableDeadLetteringOnMessageExpiration = $False,          # optional    default to false
    [String]$ForwardDeadLetteredMessagesTo = $Null,                  # optional    default to null
    [String]$ForwardTo = $Null,                                      # optional    default to null
    [Int]$LockDuration = 30,                                         # optional    default to 30
    [Int]$MaxDeliveryCount = 10,                                     # optional    default to 10
    [Bool]$RequiresSession = $False,                                 # optional    default to false
    [Bool]$SupportOrdering = $True,                                  # optional    default to true
    [String]$UserMetadata = $Null,                                   # optional    default to null
    [String]$SqlFilter = "1=1",                                      # optional    default to null
    [String]$SqlRuleAction = $Null,                                  # optional    default to null
    [Parameter(Mandatory = $true)]
    [ValidatePattern("^[a-z0-9]*$")]
    [String]$Namespace                                               # required    needs to be alphanumeric
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
    Exit
}

$sbr = Get-SBAuthorizationRule -Namespace $Namespace

# Create the NamespaceManager object to create the subscription
Write-Host "Creating a NamespaceManager object for the [$Namespace] namespace..."
$NamespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($sbr.ConnectionString);
Write-Host "NamespaceManager object for the [$Namespace] namespace has been successfully created."

# Check if the topic exists
if (!$NamespaceManager.TopicExists($TopicPath))
{
    Write-Output "The [$TopicPath] topic does not exit in the [$Namespace] namespace." 
    Exit
}

# Check if the subscription already exists
if ($NamespaceManager.SubscriptionExists($TopicPath, $Name))
{
    Write-Output "The [$Name] subscription already exists in the [$Namespace] namespace." 
}
else
{
    Write-Output "Creating the [$Name] subscription for the [$TopicPath] topic in the [$Namespace] namespace..."
    Write-Output " - SqlFilter: [$SqlFilter]"
    Write-Output " - SqlRuleAction: [$SqlRuleAction]"
    $SubscriptionDescription = New-Object -TypeName Microsoft.ServiceBus.Messaging.SubscriptionDescription -ArgumentList $TopicPath, $Name
    #if ($AutoDeleteOnIdle -ge 5)
    #{
    #    $SubscriptionDescription.AutoDeleteOnIdle = [System.TimeSpan]::FromMinutes($AutoDeleteOnIdle)
    #}
    if ($DefaultMessageTimeToLive -gt 0)
    {
        $SubscriptionDescription.DefaultMessageTimeToLive = [System.TimeSpan]::FromMinutes($DefaultMessageTimeToLive)
    }
    $SubscriptionDescription.EnableBatchedOperations = $EnableBatchedOperations
    $SubscriptionDescription.EnableDeadLetteringOnFilterEvaluationExceptions = $EnableDeadLetteringOnFilterEvaluationExceptions
    $SubscriptionDescription.EnableDeadLetteringOnMessageExpiration = $EnableDeadLetteringOnMessageExpiration
    #$SubscriptionDescription.ForwardDeadLetteredMessagesTo = $ForwardDeadLetteredMessagesTo
    #$SubscriptionDescription.ForwardTo = $ForwardTo
    if ($LockDuration -gt 0)
    {
        $SubscriptionDescription.LockDuration = [System.TimeSpan]::FromSeconds($LockDuration)
    }
    $SubscriptionDescription.MaxDeliveryCount = $MaxDeliveryCount
    $SubscriptionDescription.RequiresSession = $RequiresSession
    $SubscriptionDescription.UserMetadata = $UserMetadata
    
    $SqlFilterObject = New-Object -TypeName Microsoft.ServiceBus.Messaging.SqlFilter -ArgumentList $SqlFilter
    #$SqlRuleActionObject = New-Object -TypeName Microsoft.ServiceBus.Messaging.SqlRuleAction -ArgumentList $SqlRuleAction
    $RuleDescription = New-Object -TypeName Microsoft.ServiceBus.Messaging.RuleDescription
    $RuleDescription.Filter = $SqlFilterObject
    #$RuleDescription.Action = $SqlRuleActionObject

    $NamespaceManager.CreateSubscription($SubscriptionDescription, $RuleDescription);

    Write-Host "The [$Name] subscription for the [$TopicPath] topic has been successfully created."
}

# Mark the finish time of the script execution
$finishTime = Get-Date

# Output the time consumed in seconds
$TotalTime = ($finishTime - $startTime).TotalSeconds
Write-Output "The script completed in $TotalTime seconds."