param 
(
	[string] $AccountNameToCopy,
	[string] $NewAccountName,
	[string] $DisplayAccountName,
	[string] $NewPassword,
	[bool]   $Enabled
)


function CreateAdAccountByCopy
{
	
	Process
	{
		Import-Module ActiveDirectory -Force 

		$retVal = 0
		
		[bool] $accountExists = AdAccountExists $AccountNameToCopy
		if (-Not $accountExists)
		{
			$msg =	"AdAccount to copy does not exist: [$AccountNameToCopy]"
			write-error $msg
			throw $msg
		}
		Write-Host "AD Account [$AccountNameToCopy] to copy exists."
		
		[bool] $newAccountExists = AdAccountExists $NewAccountName
		if (-Not $newAccountExists)
		{
			Write-Host "Creating AD account [$NewAccountName] based on account [$AccountNameToCopy]"
            $secureStringPassword = ConvertTo-SecureString $NewPassword -AsPlainText -Force
            $instanceToCopy = Get-AdUser $AccountNameToCopy
            $distinguishedNameOfUserToCopy = $instanceToCopy.DistinguishedName
            #remove the user name from the distinguished name to get the org unit
            $orgUnitOfUserToCopy = $distinguishedNameOfUserToCopy.Substring($distinguishedNameOfUserToCopy.IndexOf(',') + 1)
            Write-Host "About to create user [$NewAccountName] in OrgUnit [$orgUnitOfUserToCopy]"

			$description = "Service Account for $NewAccountName" 
            New-ADUser -Name $DisplayAccountName -GivenName $DisplayAccountName -SamAccountName $NewAccountName  -Instance $instanceToCopy -DisplayName $DisplayAccountName -AccountPassword $secureStringPassword -CannotChangePassword $true -PasswordNeverExpires $true -Path $orgUnitOfUserToCopy -Description $description -Enabled $Enabled

            Write-Host "Created User [$NewAccountName] in OrgUnit [$orgUnitOfUserToCopy]"
		}
		else
		{
			Write-Host "Ad Account to create already exists: [$NewAccountName]"
			$retVal = 14;
		}
		
		foreach ($adGroupMember in Get-ADUser -Identity $AccountNameToCopy -Properties memberof | Select-Object -ExpandProperty memberof  )
		{
            [bool] $isAlreadyGroupMember = $false
            foreach ($currentGroupMember in Get-ADUser -Identity $NewAccountName -Properties memberof | Select-Object -ExpandProperty memberof  )
		    {
                if ($currentGroupMember -eq $adGroupMember)
                {
                    $isAlreadyGroupMember = $true
                }
            }
            
            if (-Not $isAlreadyGroupMember)
            {
                Write-Host "Adding [$NewAccountName] to be member of [$adGroupMember]"
		        Add-ADGroupMember $adGroupMember -Members $NewAccountName 	
                Write-Host "Added [$NewAccountName] to be member of [$adGroupMember]"
            }
            else
            {
                Write-Host "[$NewAccountName] is already a member of [$adGroupMember]"
            }
		}

		$retVal;
	
   }
}


function AdAccountExists 
{
	[CmdletBinding()]
	param 
	(
		[string] $AccountName
	)
	
	Process
	{
		Import-Module ActiveDirectory -Force 
		
		[bool] $accountExists = $false;
		try 
        {
            $userRecord = Get-ADUser $accountName
			$accountExists = $true
        }
        catch
        {
            $accountExists = $false
        }
		
		return $accountExists
	}
}

CreateAdAccountByCopy