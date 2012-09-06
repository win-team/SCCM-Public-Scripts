#Create accounts and shares for SCCM

#references
. .\AD-Functions.ps1

#variables
Function Read-Variable($variable)
	{
		Switch($variable)
			{
				"domainSuffix"
					{
						$retval = $domainSuffix
					}
			}
	}

#Site Variables
$SiteCode = "CHM"
$domainSuffix = "chemistry.ohio-state.edu"
$aclGroupOuDn = "OU=Capability Resource Groups,OU=Security Groups,DC=chemistry,DC=ohio-state,DC=edu"
$roleGroupOuDn = "OU=Role Groups,OU=Security Groups,DC=chemistry,DC=ohio-state,DC=edu"


#test vars
$dnFail = $null
$dnFail = $false
If((Check-DNExists $aclGroupOuDn) -eq $false)
	{
		$dnFail = $true
		Write-Host -f magenta "Failed to find ACL Group DN at $aclGroupOuDn."
	}
If((Check-DNExists $aclGroupOuDn) -eq $false)
	{
		$dnFail = $true
		Write-Host -f magenta "Failed to find role Group DN at $roleGroupOuDn."
	}
If($dnFail -eq $true)
	{Exit}

#Create Initial Groups
$aclGroupNames = @()
$aclGroupNames += "ACL_SCCM-" + $siteCode + "1_SourceShare_AllowRead"
$aclGroupNames += "ACL_SCCM-" + $siteCode + "1_SourceShare_AllowReadWrite"
$aclGroupNames += "ACL_SCCM-" + $siteCode + "1_PrivateSourceShare_AllowRead"
$aclGroupNames += "ACL_SCCM-" + $siteCode + "1_PrivateSourceShare_AllowReadWrite"
$aclGroupNames += "ADM_SCCM-" + $siteCode + "1"

$roleGroupNames = @()
$roleGroupNames += $siteCode + " SCCM Admins"
$roleGroupNames += $siteCode + " SCCM Users"

#ACL's
$aclGroupNames | % {
	$action = $false
	$cn = Sanitize-GroupCN $_
	If((Check-DoesGroupExist $cn) -eq $false)
		{
			$action = Create-Group $cn $aclGroupOuDn
			If($action -eq $false)
				{
					Write-Host -f magenta "Failed to create group $cn."
					Exit
				}
			Else
				{Write-Host -f green "Created group $cn."}
		}
	Else
		{Write-Host -f green "Group $cn already exists."}
	
	$DN = Get-DNbyCN $cn
	$objGroup = [adsi]("LDAP://" + $DN)
	$sAMAccountName = Pull-LDAPAttribute $objGroup "sAMAccountName"
	If($sAMAccountName -ne $cn)
		{
			Write-host -f green "Setting group $cn sAMAccountName."
			$action = Put-LDAPAttribute $objGroup "sAMAccountName" $cn
		}
	
}

#Roles
$roleGroupNames | % {
	$action = $false
	$cn = Sanitize-GroupCN $_
	If((Check-DoesGroupExist $cn) -eq $false)
		{
			$action = Create-Group $cn $roleGroupOuDn
			If($action -eq $false)
				{
					Write-Host -f magenta "Failed to create group $cn."
					Exit
				}
			Else
				{Write-Host -f green "Created group $cn."}
		}
	Else
		{Write-Host -f green "Group $cn already exists."}
		
	$DN = Get-DNbyCN $cn
	$objGroup = [adsi]("LDAP://" + $DN)
	$sAMAccountName = Pull-LDAPAttribute $objGroup "sAMAccountName"
	If($sAMAccountName -ne $cn)
		{
			Write-host -f green "Setting group $cn sAMAccountName."
			$action = Put-LDAPAttribute $objGroup "sAMAccountName" $cn
		}
}

#Nest SCCM Admins into Read-Writes and ADM
$sourceCNs = @()
$sourceCNs += "ADM_SCCM-" + $siteCode + "1"
$sourceCNs += "ACL_SCCM-" + $siteCode + "1_SourceShare_AllowReadWrite"
$sourceCNs += "ACL_SCCM-" + $siteCode + "1_PrivateSourceShare_AllowReadWrite"

$mbrCn = $siteCode + " SCCM Admins"
$mbrDn = Get-DNbyCN $mbrCn

$sourceCNs | % {
	$action = $false
	$sourceDN = Get-DNbyCN $_
	If ((Check-IsMemberOfGroup $mbrDn $sourceDN) -eq $false)
		{
			$action = Add-ToGroup $mbrDN $sourceDN
			If($action -eq $false)
				{
					Write-Host -f magenta "Failed to add $mbrCN to the group $_."
					Exit
				}
			Else
				{Write-Host -f green "Successfully added $mbrCN to the group $_."}
		}
	Else
		{Write-Host -f green "$mbrCN is already a member of $_"}
}

#Nest SCCM Users into Read-Writes
$sourceCNs = @()
$sourceCNs += "ACL_SCCM-" + $siteCode + "1_SourceShare_AllowReadWrite"
$sourceCNs += "ACL_SCCM-" + $siteCode + "1_PrivateSourceShare_AllowReadWrite"

$mbrCn = $siteCode + " SCCM Users"
$mbrDn = Get-DNbyCN $mbrCn

$sourceCNs | % {
	$action = $false
	$sourceDN = Get-DNbyCN $_
	If ((Check-IsMemberOfGroup $mbrDn $sourceDN) -eq $false)
		{
			$action = Add-ToGroup $mbrDN $sourceDN
			If($action -eq $false)
				{
					Write-Host -f magenta "Failed to add $mbrCN to the group $_."
					Exit
				}
			Else
				{Write-Host -f green "Successfully added $mbrCN to the group $_."}
		}
	Else
		{Write-Host -f green "$mbrCN is already a member of $_"}
}
