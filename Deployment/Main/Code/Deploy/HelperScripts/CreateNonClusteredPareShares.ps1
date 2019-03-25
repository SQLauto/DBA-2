# This script is designed to create the pare folder structure and shares on a single box
# It will not add the permissions, you will need to do that manually :(
# See the environment xls for details of permissions settings

function CreateShare($Foldername, $Sharename) 
{ 
	# Create Share but check to make sure it isn’t already there
	if (!(GET-WMIOBJECT Win32_Share | Where-Object -FilterScript {$_.Name -eq $Sharename})) 
	{
		$Shares = [wmiclass]"Win32_Share"
		$results = $Shares.Create($Foldername, $Sharename, 0 ,0)

		if ($results.ReturnValue -eq 0) 
		{
			# Share created ok
			write-output "Created $Sharename"
		} 
		else 
		{
			# Error creating share
			write-output "Failed to create $Sharename ERROR:" $results.returnvalue
		}
	} 
	else 
	{
		# Share name already exists
		write-output "$Sharename already exists"  
	}

	write-output ""
}

function CreateFolder($Foldername)
{
    if (!(TEST-PATH $Foldername)) 
    {
        NEW-ITEM $Foldername -type Directory
        write-output "Created $Foldername"
    }
	else
	{
		write-output "$Foldername already exists"
	}
}


CreateFolder "D:\TapFileProcessor\Unprocessed"
CreateFolder "D:\TapFileProcessor\Loading"
CreateFolder "D:\TapFileProcessor\Processed"
CreateFolder "D:\TapFileProcessor\Failed"
CreateFolder "D:\TapFileProcessor\Invalid"
CreateFolder "D:\PareResponseFiles"
CreateFolder "D:\PareResponseFiles\Unprocessed"
CreateFolder "D:\PareResponseFiles\Loading"
CreateFolder "D:\PareResponseFiles\Processed"
CreateFolder "D:\PareResponseFiles\Failed"
CreateFolder "D:\PareResponseFiles\Invalid"
CreateFolder "D:\TapResultFile"
CreateFolder "D:\StatusList"
CreateFolder "D:\SettlementResponseFiles"
CreateFolder "D:\SettlementResponseFiles\Failed"
CreateFolder "D:\SettlementResponseFiles\Invalid"
CreateFolder "D:\SettlementResponseFiles\Unprocessed"
CreateFolder "D:\SettlementResponseFiles\Processed"
CreateFolder "D:\RefundFiles"
CreateFolder "D:\RefundFiles\Failed"
CreateFolder "D:\RefundFiles\Invalid"
CreateFolder "D:\RefundFiles\Unprocessed"
CreateFolder "D:\RefundFiles\Processed"
CreateFolder "D:\RefundFiles\Response"
CreateFolder "D:\RevenueStatusListFiles"
CreateFolder "D:\RevenueStatusListFiles\Failed"
CreateFolder "D:\RevenueStatusListFiles\Invalid"
CreateFolder "D:\RevenueStatusListFiles\Unprocessed"
CreateFolder "D:\RevenueStatusListFiles\Processed"
CreateFolder "D:\RevenueStatusListFiles\Response"
CreateFolder "D:\SettlementValidationResult"
CreateFolder "D:\SettlementValidationResult\Failed"
CreateFolder "D:\SettlementValidationResult\Invalid"
CreateFolder "D:\SettlementValidationResult\Unprocessed"
CreateFolder "D:\SettlementValidationResult\Processed"
CreateFolder "D:\RequestCardPayment"
CreateFolder "D:\TdrFileProcessor"
CreateFolder "D:\TdrFileProcessor\Unprocessed"
CreateFolder "D:\TdrFileProcessor\Loading"
CreateFolder "D:\TdrFileProcessor\Processed"
CreateFolder "D:\TdrFileProcessor\Failed"
CreateFolder "D:\TdrFileProcessor\Invalid"

CreateShare "D:\TapFileProcessor" "TapFileProcessor"
CreateShare "D:\TapResultFile" "TapResultFile"
CreateShare "D:\TdrFileProcessor" "TdrFileProcessor"
CreateShare "D:\SettlementValidationResult" "SettlementValidationResult"
CreateShare "D:\SettlementResponseFiles" "SettlementResponseFiles"
CreateShare "D:\PareResponseFiles" "PareResponseFiles"
CreateShare "D:\StatusList" "StatusList"
CreateShare "D:\RefundFiles" "RefundFiles"
CreateShare "D:\RevenueStatusListFiles" "RevenueStatusListFiles"
CreateShare "D:\RequestCardPayment" "RequestCardPayment"