#create sccm shares
. .\AD-Functions.ps1

#userVals
$sourceLocalPath = "C:\shares"
$sccmServerName = "support-08"
$domainShort = "chemistry"
$SiteCode = "CHM"
$sccmSourceReadGroup = "ACL_SCCM-" + $siteCode + "1_SourceShare_AllowRead"
$sccmSourceReadWriteGroup = "ACL_SCCM-" + $siteCode + "1_SourceShare_AllowReadWrite"
$sccmPrivateSourceReadGroup = "ACL_SCCM-" + $siteCode + "1_PrivateSourceShare_AllowRead"
$sccmPrivateSourceReadWriteGroup = "ACL_SCCM-" + $siteCode + "1_PrivateSourceShare_AllowReadWrite"
#$sccmNetworkAccessAccount = ("sccm-" + $siteCode + "-naa").ToLower()
$sccmNetworkAccessAccount = ("sccm-naa").ToLower()

#folder structure
$folders = @()
$folders += "source"
$folders += "source\packages"
$folders += "source\driverpackages"
$folders += "source\driversource"
$folders += "source\images"
$folders += "source\updates"
$folders += "source\temp"
$folders += "source\images"
$folders += "source\bootimages"
$folders += "source\ossource"
$folders += "captures"
$folders += "privateSource"

###FUNCTIONS###

Function Read-Variable($varName)
	{
		Switch($varName)
			{
				"domainShort"
					{$retval = $domainShort}
				"sccmSourceReadGroup"
					{$retval = $sccmSourceReadGroup}
				"sccmSourceReadWriteGroup"
					{$retval = $sccmSourceReadWriteGroup}
				"fileserver"
					{$retval = $sccmServerName}
				"pathToSubInACL"
					{$retval = $sourceLocalPath + "\subinacl.exe"}
			}
		Return $retval
	}

Function Build-SourceShareDACL($sccmServerName,$hshUserAccess)
	{
		#References
		#http://mow001.blogspot.com/2006/05/powershell-import-shares-and-security.html
		#http://thepowershellguy.com/blogs/posh/archive/2007/01/23/powershell-converting-accountname-to-sid-and-vice-versa.aspx
		$domain = Read-Variable "domainShort"
		$mode = "Full"
		$targetServer = $sccmServerName
		
		# Get the needed WMI Classes
		$strWMI = $null
		$strWMI = "//" + $targetServer + "/root/cimv2:Win32_SecurityDescriptor"
		$SdObject = [wmiclass]$strWMI
		$sd = $SdObject.CreateInstance()
		#Create Objects for SCCM Server AD Account
		$strWMI = $null
		$strWMI = "//" + $targetServer + "/root/cimv2:Win32_ACE"
		$AceObject = [wmiclass]$strWMI
		$strWMI = $null
		$strWMI = "//" + $targetServer + "/root/cimv2:Win32_Trustee"
		$TrusteeObject = [wmiclass]$strWMI
		$Ace_SccmServer = $AceObject.CreateInstance()
		$Trustee_SCCMServer = $TrusteeObject.CreateInstance()
		
		#Start the security descriptor
		$SdDaclList = @()
		$Sd.DACL = @()
				
		$users = $hshUserAccess.Keys
		$users | % {
			#Create Objects for SCCM Server SYSTEM Account
			$strWMI = $null
			$strWMI = "//" + $targetServer + "/root/cimv2:Win32_ACE"
			$AceObjectClass = [wmiclass]$strWMI
			$strWMI = $null
			$strWMI = "//" + $targetServer + "/root/cimv2:Win32_Trustee"
			$TrusteeObjectClass = [wmiclass]$strWMI
			$AceObject = $AceObjectClass.CreateInstance()
			$TrusteeObject = $TrusteeObjectClass.CreateInstance()
			
			$domain = $_.Split("\")[0]
			If($domain -like "builtin" -or $domain -like ".")
				{$domain = $null}
			$name = $_.Split("\")[1]
			$rights = $hshUserAccess.$_
			
			#Get the SID, and convert it into binary form
			$TrusteeObject.Domain = $domain
			$TrusteeObject.Name = $name
			$SidAccountObject = New-Object System.Security.Principal.NtAccount($domain,$name)
			$StringSid = $SidAccountObject.Translate([system.security.principal.securityidentifier])
			[byte[]]$BinarySid = ,0 * $StringSid.BinaryLength
			$StringSid.GetBinaryForm($BinarySid,0)
			$TrusteeObject.SID = $BinarySid
			
			#Set up the ACE for the sccm server system account.
			If($rights -like "read"){$AceObject.AccessMask = 1179817}
			Else{$AceObject.AccessMask = ([System.Security.AccessControl.FileSystemRights]$rights).Value__}
			$AceObject.AceType = 0
			$AceObject.AceFlags = 3
			$AceObject.Trustee = $TrusteeObject.psobject.baseobject
			
			$SdDaclList += ($AceObject.psobject.baseobject)
		}
		
		$sd.DACL = $sdDaclList
		Return $sd
	}

Function Set-FolderPermissions($targetPath,$hshUserAccess,$optional_rootPath)
	{
		$failThisFunction = $null
		$failThisFunction = $false
		
		#get root path
		If($failThisFunction -eq $false)
			{
				$rootPath = $null
				If($optional_rootPath -eq $null)
					{
						$rootPath = Trim-OneFolderLevel $targetPath
						If($rootPath -eq $false -or $rootPath -eq $null)
							{
								$warningMsg = "ERROR`t`t`tCannot get permissions from root folder """ + $rootPath + """."
								Throw-Warning $warningMsg
								$failThisFunction = $true
							}
						ElseIf((Test-Path $rootPath) -eq $false)
							{
								$warningMsg = "ERROR`t`t`tCannot get permissions from root folder """ + $rootPath + """."
								Throw-Warning $warningMsg
								$failThisFunction = $true
							}
					}
				Else
					{$rootPath = $optional_RootPath}
			}
		
		#lets fix these perms!
		If($failThisFunction -eq $false)
			{
				#set the perms
				If($failThisFunction -eq $false)
					{
						#Get-ACL of Parent
						$msg = "ACTION`t`tReading ACL from root path """ + $rootPath + """."
						Write-Out $msg "darkcyan" 4
						$rootAcl = Get-ACL $rootPath
						$childAcl = Get-ACL $rootPath
						
						#Set Owners
						$scriptUser = $env:username
						$msg = "ACTION`t`tTaking ownership of target path """ + $targetPath + """."
						Write-Out $msg "darkcyan" 4
						Set-FolderOwner $scriptUser $targetPath
						
						$inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"
						$propagation = [system.security.accesscontrol.PropagationFlags]"None"
						$access = [System.Security.AccessControl.AccessControlType]"Allow"
						
						$users = $hshUserAccess.Keys
						Foreach($user in $users)
							{
								If($user -eq "BUILTIN\SYSTEM")
									{}
								Else
									{
										$rights = $hshUserAccess.$user
										If($rights -like "*read*"){$rights = "ReadAndExecute, Synchronize"}
										$msg = "Action`t`t`tBuilding ACE for object """ + $user + """."
										Write-Out $msg "darkcyan" 4
										$dirAccessRule = new-object System.Security.AccessControl.FileSystemAccessRule($user,$rights,$inherit,$propagation,$access)
										$dirAccessRule.AccessToString | out-null
										$rootACL.AddAccessRule($dirAccessRule)
									}
							}
						
						#Msgboard Post on literal character problem (by jonwalz)
						##http://www.powershellcommunity.org/Forums/tabid/54/aff/1/aft/35/afv/topic/Default.aspx
						
						#set root acl
						$msg = "ACTION`t`tWriting ACL to target path """ + $targetPath + """."
						Write-Out $msg "darkcyan" 4
						Set-ACL -aclObject $rootAcl -path "$targetPath"
						
						#set child acl's
						$msg = "ACTION`t`tWriting ACL to children path """ + $targetPath + "\*""."
						Write-Out $msg "darkcyan" 4
						$regex = Read-Variable "ACLRegex"
						Get-ChildItem -recurse -force -path $targetPath -erroraction silentlycontinue | `
							% {
								$path = $_.fullname.ToString()
								If($path -match $regex)
									{Set-ACL -aclObject $childAcl -path $path}
								}
						
						#fix Ownership
						$destOwner = $null
						$destOwner = "BUILTIN\Administrators"
						$msg = "ACTION`t`tGiving ownership of target path """ + $targetPath + """ to """ + $destOwner + """."
						Write-Out $msg "darkcyan" 4
						set-folderOwner $destOwner $targetPath
					}
			}
		
		$results = $null
		If($failThisfunction -eq $true)
			{$results = $false}
		Else
			{$results = $true}
		return $results
	}

Function Set-FolderOwner($sAMAccountName,$targetPath)
	{
		$fileServer = Read-Variable "fileserver"
		
		#add "domain\" if needed
		If($sAMAccountName -match "\\")
			{$newOwner = $sAMAccountName}
		Else
			{
				$shortDomain = Read-Variable "domainShort"
		 		$newOwner = $shortDomain + "\" + $sAMAccountName
		 	}
		
 		#Build commands
 		$pathToSubInACL = Read-Variable "pathToSubInACL"
 		If($PathToSubInACL -eq $null -or $pathToSubInACL -eq $false -or $pathToSubInACL -eq "")
 			{
 				$msg = "Error`t`tCould not read the path to SubInACL.exe from the script settings file."
 				Throw-Warning $msg
 				$failThisFunction = $true
 			}
 		
 		$command1 = $pathToSubInACL + " /nostatistic /noverbose /file """ + $TargetPath + """ /setowner=" + $NewOwner
 		$command2 = $pathToSubInACL + " /nostatistic /noverbose /subdirectories """ + $TargetPath + "\*"" /setowner=" + $NewOwner
 		#Run commands
		
		#run first set-owner expression
		$command1 = $pathToSubInACL + " /nostatistic /noverbose /file """ + $TargetPath + """ /setowner=" + $NewOwner
 		$results = $null
		$results = Run-RemoteCommand $fileServer $command1
		
		#run second second-owner expression
		$command2 = $pathToSubInACL + " /nostatistic /noverbose /subdirectories """ + $TargetPath + "\*"" /setowner=" + $NewOwner
 		$results = $null
		$results = Run-RemoteCommand $fileServer $command2
		Return $results
	}

Function Create-Share($shareName,$sharePath,$fileserver)
	{
		$newSharePath = $null
		If($sharePath -like "\\*")
			{$newSharePath = Convert-UNCPathToSharePath $sharePath $fileserver}
		Else
			{$newSharePath = $sharePath}
		[string]$newSharePath = Trim-TrailingSlash $newSharePath
		
		If($fileserver -eq $null -or $fileserver -eq "")
			{$fileserver = Read-Variable "fileserver"}
		$strWMI = $null
		$strWMI = "\\" + $fileserver + "\root\CIMv2:Win32_Share"
		
		$Win32ShareClass = $null
		$Win32ShareClass = [wmiclass]$strWMI
		
		$action = $Win32ShareClass.Create($newSharePath,$ShareName,"0",$Null,$Null)
		
		#Make sure the share was created
		$results = $false
		$i = $null
		$i = 0
		While($results -eq $false)
			{
				$results = Check-DoesShareExist $shareName $fileserver
				If($results -eq $true)
					{Break}
				Else
					{
						Sleep -s 1
						$i++
					}
				#Break after 10 tries
				If($i -ge 10)
					{
						$warningMsg = "ERROR`tFailed to create share."
						Throw-Warning $warningMsg
						$failFunction = $true
						Break
					}
			}
		
		If($failFunction -eq $true)	
			{$results = $false}
		
		Return $results
	}

Function Check-DoesShareExist($shareName,$fileserver)
	{
		If($fileServer -eq $null -or $fileServer -eq "")
			{$fileServer = Read-Variable "fileserver"}
		$shareExists = $null
		$sharePath = $null
		$sharePath = Get-SharePath $shareName $fileserver
		If($sharePath -eq $false -or $sharePath -eq $null)
			{$shareExists = $false}
		Else
			{$shareExists = $true}
		Return $shareExists
	}

Function Get-SharePath($shareName,$fileserver)
	{
		Trap{continue;}
		If($fileServer -eq $null -or $fileServer -eq "")
			{$fileServer = Read-Variable "fileserver"}
		$strWMI = $null
		$strWMI = "\\" + $fileserver + "\root\cimv2:win32_share.name='" + $shareName + "'"
		$sharePath = $null
		$sharePath = ([wmi]$strWMI).path
		Return $sharePath
	}

##Check prereqs
$PathToSubinacl = Read-variable "pathToSubInAcl"
If((Test-Path $PathToSubinacl) -eq $false)
	{
		Write-Host -f magenta "Please install subinacl.exe at $PathToSubinacl"
		Exit
	}

#if naa DNE, create it
$UserDN = Get-DNbySamaccountName $sccmNetworkAccessAccount
If($userDN -eq $false)
	{
		Write-Host -f magenta "The sccm network access account named $sccmNetworkAccessAccount doesn't exist."
		Exit
	}

#create folder structure
If((test-path $sourceLocalPath) -eq $false)
	{mkdir $sourceLocalPath | out-null}

$folders | % {
	$path = $sourceLocalPath + "\" + $_
	If((Test-Path $path) -eq $false)
		{mkdir $path | out-null}
}

#Create Shares
$shares = @()
$shares += "source$"
$shares += "captures$"
$shares += "privateSource$"

$shares | % {
	$shareName = $_
	$sharePath = $sourceLocalPath + "\" + ($shareName.TrimEnd("$"))
	$action = Create-Share $shareName $sharePath $sccmServerName
	
	If($ShareName -like "private*")
		{
			#hshUserAccess
			$hshUserAccess = $null
			$hshUserAccess = @{}
			$hshUserAccess.Add("BUILTIN\SYSTEM","FullControl")
			$hshUserAccess.Add(($domainShort + "\" + $sccmNetworkAccessAccount),"Read")
			$hshUserAccess.Add(($domainShort + "\" + $sccmPrivateSourceReadGroup),"Read")
			$hshUserAccess.Add(($domainShort + "\" + $sccmPrivateSourceReadWriteGroup),"FullControl")
			$hshUserAccess.Add(($domainShort + "\" + $SCCMServerName + "$"),"FullControl")
		}
	ElseIf($shareName -like "source*")
		{
			#hshUserAccess
			$hshUserAccess = $null
			$hshUserAccess = @{}
			$hshUserAccess.Add("BUILTIN\SYSTEM","FullControl")
			$hshUserAccess.Add(($domainShort + "\" + $sccmNetworkAccessAccount),"Read")
			$hshUserAccess.Add(($domainShort + "\" + $sccmSourceReadGroup),"Read")
			$hshUserAccess.Add(($domainShort + "\" + $sccmSourceReadWriteGroup),"FullControl")
			$hshUserAccess.Add(($domainShort + "\" + $SCCMServerName + "$"),"FullControl")
		}
	ElseIf($shareName -like "captures*")
		{
			#hshUserAccess
			$hshUserAccess = $null
			$hshUserAccess = @{}
			$hshUserAccess.Add("BUILTIN\SYSTEM","FullControl")
			$hshUserAccess.Add(($domainShort + "\" + $sccmNetworkAccessAccount),"FullControl")
			$hshUserAccess.Add(($domainShort + "\" + $sccmSourceReadGroup),"Read")
			$hshUserAccess.Add(($domainShort + "\" + $sccmSourceReadWriteGroup),"FullControl")
			$hshUserAccess.Add(($domainShort + "\" + $SCCMServerName + "$"),"FullControl")
		}
	
	#set share perms
	$strWMI = $null
	$strWMI = "\\" + $sccmServerName + "\root\cimv2:win32_share.name='" + $shareName + "'"
	$objShare = [wmi]$strWMI
	$objShare_NewSD = $null
	$objShare_NewSD = Build-SourceShareDACL $sccmServerName $hshUserAccess
	$objShare.SetShareInfo($Null,$Null,$objShare_NewSD.PSObject.BaseObject) | out-null
	
	#set folder perms
	Set-FolderPermissions $sharePath $hshUserAccess
}

