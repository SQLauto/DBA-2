function Test-FileShare
{
    <#
    .SYNOPSIS
    Tests if a file/SMB share exists on the local computer.

    .DESCRIPTION
    The `Test-FileShare` function uses WMI to check if a file share exists on the local computer. If the share exists, `Test-FileShare` returns `$true`. Otherwise, it returns `$false`.

    .LINK
    Get-FileShare

    .LINK
    Get-FileSharePermission

    .LINK
    Install-FileShare

    .LINK
    Uninstall-FileShare

    .EXAMPLE
    Test-FileShare -Name 'CarbonShare'
	Test-FileShare -Name 'CarbonShare' -ComputerName "Server"

    Demonstrates how to test of a file share exists.
    #>
    [CmdletBinding(DefaultParameterSetName="ByName")]
    param(
		[parameter(ParameterSetName="ByName", Mandatory=$true, Position=0)]
        [string]
        # The name of a specific share to retrieve. Wildcards accepted. If the string contains WMI sensitive characters, you'll need to escape them.
        $Name,
		[parameter(ParameterSetName="ByPath", Mandatory=$true, Position=0)]
        [string]
        # The name of a specific share to retrieve. Wildcards accepted. If the string contains WMI sensitive characters, you'll need to escape them.
        $Path,
		[string]$ComputerName = "."
    )

    $share = Get-FileShare @PSBoundParameters

    $null -ne $share
}

function Get-FileShare
{
    <#
    .SYNOPSIS
    Gets the file/SMB shares on the local computer.

    .DESCRIPTION
    The `Get-FileShare` function uses WMI to get the file/SMB shares on the current/local computer. The returned objects are `Win32_Share` WMI objects.

    Use the `Name` paramter to get a specific file share by its name. If a share with the given name doesn't exist, an error is written and nothing is returned.

    The `Name` parameter supports wildcards. If you're using wildcards to find a share, and no shares are found, no error is written and nothing is returned.

    .LINK
    https://msdn.microsoft.com/en-us/library/aa394435.aspx

    .LINK
    Get-FileSharePermission

    .LINK
    Install-FileShare

    .LINK
    Test-FileShare

    .LINK
    Uninstall-FileShare

    .EXAMPLE
    Get-FileShare

    Demonstrates how to get all the file shares on the local computer.

    .EXAMPLE
    Get-FileShare -Name 'Build'
	Get-FileShare -Path 'D:\ShareName'
	Get-FileShare -Name 'Build' -ComputerName 'Server'

    Demonstrates how to get a specific file share.

    .EXAMPLE
    Get-FileShare -Name 'Carbon*'

    Demonstrates that you can use wildcards to find all shares that match a wildcard pattern.
    #>
    [CmdletBinding(DefaultParameterSetName="ByName")]
    param(
		[parameter(ParameterSetName="ByName", Mandatory=$true, Position=0)]
        [string]
        # The name of a specific share to retrieve. Wildcards accepted. If the string contains WMI sensitive characters, you'll need to escape them.
        $Name,
		[parameter(ParameterSetName="ByPath", Mandatory=$true, Position=0)]
        [string]
        # The name of a specific share to retrieve. Wildcards accepted. If the string contains WMI sensitive characters, you'll need to escape them.
        $Path,
		[string]$ComputerName = "."
    )

    $filter = '(Type = 0 or Type = 2147483648)'

	switch($PSCmdlet.ParameterSetName){
		"ByName"{
			$filter = '{0} and Name = ''{1}''' -f $filter,$Name
			$shares = Get-WmiObject -Class 'Win32_Share' -Filter $filter -ComputerName $ComputerName
		}
		"ByPath"{
			#TODO: See if we can filter by Path - Path='zx' does not work
			$shares = Get-WmiObject -Class 'Win32_Share' -Filter $filter -ComputerName $ComputerName | Where-Object {$_.Path -eq $Path}
		}

	}

    $shares
}

function Remove-FileShare
{
    <#
    .SYNOPSIS
    Uninstalls/Removes a file share.

    .DESCRIPTION
    The `Remove-FileShare` function uses WMI to uninstall/remove a file share from the local computer, if it exists. If the file shares does not exist, no errors are written and nothing happens. The directory on the file system the share points to is not removed.

    .LINK
    Get-FileShare

    .LINK
    Get-FileSharePermission

    .LINK
    New-FileShare

    .LINK
    Test-FileShare

    .EXAMPLE
    Remove-FileShare -Name 'CarbonShare'

    Demonstrates how to uninstall/remove a share from the local computer. If the share does not exist, `Uninstall-FileShare` silently does nothing (i.e. it doesn't write an error).
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of a specific share to uninstall/delete. Wildcards accepted. If the string contains WMI sensitive characters, you'll need to escape them.
        $Name,
		[string]$ComputerName = "."
    )

    $errors = @{
                [uint32]2 = 'Access Denied';
                [uint32]8 = 'Unknown Failure';
                [uint32]9 = 'Invalid Name';
                [uint32]10 = 'Invalid Level';
                [uint32]21 = 'Invalid Parameter';
                [uint32]22 = 'Duplicate Share';
                [uint32]23 = 'Restricted Path';
                [uint32]24 = 'Unknown Device or Directory';
                [uint32]25 = 'Net Name Not Found';
            }

    if( -not (Test-FileShare @PSBoundParameters) ) {
        return
    }

    Get-FileShare @PSBoundParameters | ForEach-Object {
        $share = $_
        $deletePhysicalPath = $false
        if( -not (Test-Path -Path $share.Path -PathType Container) ) {
            New-Item -Path $share.Path -ItemType 'Directory' -Force | Out-Null
            $deletePhysicalPath = $true
        }

        if( $PSCmdlet.ShouldProcess( ('{0} ({1})' -f $share.Name,$share.Path), 'delete' ) ) {
            Write-Host ('Deleting file share ''{0}'' (Path: {1}).' -f $share.Name,$share.Path)
            $result = $share.Delete()
            if( $result.ReturnValue ) {
                Write-Error ('Failed to delete share ''{0}'' (Path: {1}). Win32_Share.Delete() method returned error code {2} which means: {3}.' -f $Name,$share.Path,$result.ReturnValue,$errors[$result.ReturnValue])
            }
        }

        if( $deletePhysicalPath -and (Test-Path -Path $share.Path) ) {
            Remove-Item -Path $share.Path -Force -Recurse
        }
    }
}

function Get-FileSharePermission
{
    <#
    .SYNOPSIS
    Gets the sharing permissions on a file/SMB share.

    .DESCRIPTION
    The `Get-FileSharePermission` function uses WMI to get the sharing permission on a file/SMB share. It returns the permissions as a `Carbon.Security.ShareAccessRule` object, which has the following properties:

     * ShareRights: the rights the user/group has on the share.
     * IdentityReference: an `Security.Principal.NTAccount` for the user/group who has permission.
     * AccessControlType: the type of access control being granted: Allow or Deny.

    The `ShareRights` are values from the `Carbon.Security.ShareRights` enumeration. There are four values:

     * Read
     * Change
     * FullControl
     * Synchronize

    If the share doesn't exist, nothing is returned and an error is written.

    Use the `Identity` parameter to get a specific user/group's permissions. Wildcards are supported.

    .LINK
    Get-FileShare

    .LINK
    New-FileShare

    .LINK
    Test-FileShare

    .LINK
    Remove-FileShare

    .EXAMPLE
    Get-FileSharePermission -Name 'Build'

    Demonstrates how to get all the permissions on the `Build` share.
    #>
    [CmdletBinding()]
    #[OutputType([Deployment.Common.Security.ShareAccessRule])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The share's name.
        $Name,
		[string]$ComputerName = ".",
        [string]
        # Get permissions for a specific identity. Wildcards supported.
        $Identity
    )

    $share = Get-FileShare -Name $Name -ComputerName $ComputerName
    if( -not $share ) {
        return
    }

    if( $Identity ) {
        if( -not [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters( $Identity ) ) {
            $Identity = Resolve-IdentityName -Name $Identity
            if( -not $Identity ) {
                return
            }
        }
    }

    $lsss = Get-WmiObject -Class 'Win32_LogicalShareSecuritySetting' -Filter "name='$Name'" -ComputerName $ComputerName
    if( -not $lsss ) {
        return
    }

    $result = $lsss.GetSecurityDescriptor()
    if( -not $result ) {
        return
    }

    if( $result.ReturnValue ) {
        $win32lsssErrors = @{
                                [uint32]2 = 'Access Denied';
                                [uint32]8 = 'Unknown Failure';
                                [uint32]9 = 'Privilege Missing';
                                [uint32]21 = 'Invalid Parameter';
                            }
        Write-Error ('Failed to get ''{0}'' share''s security descriptor. WMI returned error code {1} which means: {2}' -f $Name,$result.ReturnValue,$win32lsssErrors[$result.ReturnValue])
        return
    }

    $sd = $result.Descriptor
    if( -not $sd -or -not $sd.DACL ) {
        return
    }

    foreach($ace in $sd.DACL) {
        if( -not $ace -or -not $ace.Trustee ) {
            continue
        }

        [Deployment.Common.Security.Identity]$rId = Resolve-Identity -InputObject $ace.Trustee.SIDString
        if( $Identity -and  (-not $rId -or $rId.FullName -notlike $Identity) ) {
            continue
        }

        if( $rId ) {
            $aceId = New-Object 'Security.Principal.NTAccount' $rId.FullName
        }
        else {
            $aceId = New-Object 'Security.Principal.SecurityIdentifier' $ace.Trustee.SIDString
        }

        New-Object 'Deployment.Common.Security.ShareAccessRule' $aceId, $ace.AccessMask, $ace.AceType
    }
}

function New-FileShare {
    <#
    .SYNOPSIS
    Installs a file/SMB share.

    .DESCRIPTION
    The `New-FileShare` function installs a new file/SMB share. If the share doesn't exist, it is created. In Carbon 2.0, if a share does exist, its properties and permissions are updated in place, unless the share's path needs to change. Changing a share's path requires deleting and re-creating. Before Carbon 2.0, shares were always deleted and re-created.

    Use the `FullAccess`, `ChangeAccess`, and `ReadAccess` parameters to grant full, change, and read sharing permissions on the share. Each parameter takes a list of user/group names. If you don't supply any permissions, `Everyone` will get `Read` access. Permissions on existing shares are cleared before permissions are granted. Permissions don't apply to the file system, only to the share. Use `Grant-Permission` to grant file system permissions.

    .LINK
    Get-FileShare

    .LINK
    Get-FileSharePermission

    .LINK
    Test-FileShare

    .LINK
    Remove-FileShare

    .EXAMPLE
    New-Share -Name TopSecretDocuments -Path C:\TopSecret -Description 'Share for our top secret documents.' -ReadAccess "Everyone" -FullAccess "Analysts"

    Shares the C:\TopSecret directory as `TopSecretDocuments` and grants `Everyone` read access and `Analysts` full control.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The share's name.
        $Name,
        [Parameter(Mandatory=$true)]
		[string]$ComputerName,

        [Parameter(Mandatory=$true)]
        [string]
        # The path to the share.
        $Path,

        [string]
        # A description of the share
        $Description = '',

        [string[]]
        # The identities who have full access to the share.
        $FullAccess = @(),

        [string[]]
        # The identities who have change access to the share.
        $ChangeAccess = @(),

        [string[]]
        # The identities who have read access to the share
        $ReadAccess = @(),

        [Switch]
        # Deletes the share and re-creates it, if it exists.
        $Force,
		[switch]
		# By default, 'Everyone' will get read access. This will turn this off.
		$NoDefaultRead
    )

    function New-ShareAce {
        param(
            [Parameter(Mandatory=$true)]
            [AllowNull()]
            [string[]]
            # The identity
            $Identity,

            [Deployment.Common.Security.ShareRights]
            # The rights to grant to Identity.
            $ShareRight
        )

        if($Identity){
			$Identity | ForEach-Object{
				$identityName = $_

				$trustee = ([wmiclass]'Win32_Trustee').CreateInstance()
				[Security.Principal.SecurityIdentifier]$sid = Resolve-Identity -Name $identityName | Select-Object -ExpandProperty 'Sid'
				if( -not $sid )
				{
					continue
				}

				$sidBytes = New-Object 'byte[]' $sid.BinaryLength
				$sid.GetBinaryForm( $sidBytes, 0)

				$trustee.Sid = $sidBytes

				$ace = ([wmiclass]'Win32_Ace').CreateInstance()
				$ace.AccessMask = $ShareRight
				$ace.AceFlags = 0
				$ace.AceType = 0
				$ace.Trustee = $trustee

				$ace
			}
		}
    }

    $errors = @{
            [uint32]2 = 'Access Denied';
            [uint32]8 = 'Unknown Failure';
            [uint32]9 = 'Invalid Name';
            [uint32]10 = 'Invalid Level';
            [uint32]21 = 'Invalid Parameter';
            [uint32]22 = 'Duplicate Share';
            [uint32]23 = 'Restricted Path';
            [uint32]24 = 'Unknown Device or Directory';
            [uint32]25 = 'Net Name Not Found';
        }

    if( (Test-FileShare -Name $Name -ComputerName $ComputerName) ) {
        $share = Get-FileShare -Name $Name -ComputerName $ComputerName
        [bool]$delete = $false

        if( $Force ) {
            $delete = $true
        }

        if( $share.Path -ne $Path ) {
            Write-Verbose -Message ('[SHARE] [{0}] Path         {1} -> {2}.' -f $Name,$share.Path,$Path)
            $delete = $true
        }

        if($delete) {
            Remove-FileShare -Name $Name -ComputerName $ComputerName
        }
    }

    $shareAces = Invoke-Command -ScriptBlock {

		if ($FullAccess -and $FullAccess.Count -gt 0){New-ShareAce -Identity $FullAccess -ShareRight FullControl}
		if ($ChangeAccess -and $ChangeAccess.Count -gt 0){New-ShareAce -Identity $ChangeAccess -ShareRight Change}
		if ($ReadAccess -and $ReadAccess.Count -gt 0){New-ShareAce -Identity $ReadAccess -ShareRight Read}

		if(-not $NoDefaultRead){
			New-ShareAce -Identity 'Everyone' -ShareRight Read
		}
    }

    if(-not $shareAces) #need to ensure some access if none set
    {
        $shareAces = New-ShareAce -Identity 'Everyone' -ShareRight Read
    }

    # if we don't pass a $null security descriptor, default Everyone permissions aren't setup correctly, and extra admin rights are slapped on.
    $shareSecurityDescriptor = ([wmiclass] "Win32_SecurityDescriptor").CreateInstance()
    $shareSecurityDescriptor.DACL = $shareAces
    $shareSecurityDescriptor.ControlFlags = "0x4"

    if( -not (Test-FileShare -Name $Name -ComputerName $ComputerName) ) {
        if( -not (Test-Path -Path $Path -PathType Container) )
        {
            New-Item -Path $Path -ItemType Directory -Force | Out-String | Write-Verbose
        }

        $shareClass = Get-WmiObject -Class 'Win32_Share' -List
        Write-Verbose -Message ('[SHARE] [{0}]              Sharing {1}' -f $Name,$Path)
        $result = $shareClass.Create( $Path, $Name, 0, $null, $Description, $null, $shareSecurityDescriptor )
        if( $result.ReturnValue )
        {
            Write-Error ('Failed to create share ''{0}'' (Path: {1}). WMI returned error code {2} which means: {3}.' -f $Name,$Path,$result.ReturnValue,$errors[$result.ReturnValue])
            return
        }
    }
    else {
        $share = Get-FileShare -Name $Name -ComputerName $ComputerName
        $updateShare = $false
        if( $share.Description -ne $Description )
        {
            Write-Verbose -Message ('[SHARE] [{0}] Description  {1} -> {2}' -f $Name,$share.Description,$Description)
            $updateShare = $true
        }

        # Check if the share is missing any of the new ACEs.
        foreach( $ace in $shareAces )
        {
            $identityName = Resolve-IdentityName -InputObject $ace.Trustee.SID
            $permission = Get-FileSharePermission -Name $Name -ComputerName $ComputerName -Identity $identityName

            if( -not $permission )
            {
                Write-Verbose -Message ('[SHARE] [{0}] Access       {1}:  -> {2}' -f $Name,$identityName,([Deployment.Common.Security.ShareRights]$ace.AccessMask))
                $updateShare = $true
            }
            elseif( [int]$permission.ShareRights -ne $ace.AccessMask )
            {
                Write-Verbose -Message ('[SHARE] [{0}] Access       {1}: {2} -> {3}' -f $Name,$identityName,$permission.ShareRights,([Deployment.Common.Security.ShareRights]$ace.AccessMask))
                $updateShare = $true
            }
        }

        # Now, check that there aren't any existing ACEs that need to get deleted.
        $existingAces = Get-FileSharePermission -Name $Name -ComputerName $ComputerName
        foreach( $ace in $existingAces )
        {
            $identityName = $ace.IdentityReference.Value

            $existingAce = $ace
            if( $shareAces )
            {
                $existingAce = $shareAces | Where-Object {
                                                        $newIdentityName = Resolve-IdentityName -InputObject $_.Trustee.SID
                                                        return ( $newIdentityName -eq $ace.IdentityReference.Value )
                                                    }
            }

            if( -not $existingAce ) {
                Write-Verbose -Message ('[SHARE] [{0}] Access       {1}: {2} ->' -f $Name,$identityName,$ace.ShareRights)
                $updateShare = $true
            }
        }

        if( $updateShare ) {
            $result = $share.SetShareInfo( $share.MaximumAllowed, $Description, $shareSecurityDescriptor )
            if( $result.ReturnValue )
            {
                Write-Error ('Failed to create share ''{0}'' (Path: {1}). WMI returned error code {2} which means: {3}' -f $Name,$Path,$result.ReturnValue,$errors[$result.ReturnValue])
                return
            }
        }
    }
}