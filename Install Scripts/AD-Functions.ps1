#Common-Functions-v1.ps1

#Notes and Help
#To-Do on each new quarter
##add variables for expiration dates and switch them over
##change current quarter class string

##
## GENERAL \ POWERSHELL FUNCTIONS
##

Function Write-Win
	{
		$msgs = $null
		$msgs = @()
		$msgs += ""
		$msgs += "____    __    ____  __  .__   __."
		$msgs += "\   \  /  \  /   / |  | |  \ |  |"
		$msgs += " \   \/    \/   /  |  | |   \|  |"
		$msgs += "  \            /   |  | |  .    |"
		$msgs += "   \    /\    /    |  | |  |\   |"
		$msgs += "    \__/  \__/     |__| |__| \__|"
		$msgs += "Yee-haw."
		$msgs += ""
		Foreach($msg in $msgs)
			{Write-Out $msg "green" 1}
	}

Function Write-Fail
	{
		$msgs = $null
		$msgs = @()
		$msgs += ""
		$msgs += " ______     ___       __   __ "
		$msgs += "|   ___|   /   \     |  | |  |"
		$msgs += "|  |__    /  ^  \    |  | |  |"
		$msgs += "|   __|  /  /_\  \   |  | |  |"
		$msgs += "|  |    /  _____  \  |  | |  `----."
		$msgs += "|__|   /__/     \__\ |__| |______|"
    $msgs += "Thanks for playing."
    $msgs += ""
    Foreach($msg in $msgs)
			{Write-Out $msg "red" 1}
	}

Function Write-Log($msg,$switches)
	{
		If($gLogFile -eq $null)
			{}
		Else
			{Add-Content $gLogFile $msg}
	}

Function Write-Out($msg,$color,$msgVerbosity,$switches)
	{
		#$msg | out-file -append $gLogFile
		
		If($gVerbosityLevel -eq $null)
			{$gVerbosityLevel = 10}
		
		Write-Log $msg
		If($color -eq $null)
			{$color = "white"}
		If($msgVerbosity -le $gVerbosityLevel)
			{
				If($switches -eq "-nonewline")
					{Write-Host -nonewline -f $color "$msg"}
				Else{Write-Host -f $color "$msg"}
			}
	}

Function write-openingBlock
	{
		$CS = Gwmi Win32_ComputerSystem -Comp "."
		$computer = $CS.Name
		#$loggedInUser = $CS.UserName
		$loggedInUser = $env:username
		$dateTime = get-date
		
		$switches = ""
		If($gArrArguments -ne $null)
			{
				$i = 1
				Foreach($argument in $gArrArguments)
					{
						$switches = $switches + $argument
						If($i -lt $gArrArguments.count)
							{$switches = $switches + ", "}
						Else
							{}
						$i++
					}
			}
		$msgs = $null
		$msgs = @()
		$msgs += $gScriptName + " " + $gScriptVersion
		$msgs += "Running on " + $dateTime + " by " + $loggedInUser + " from " + $computer
		$msgs += "Verbosity Level: " + $gVerbosityLevel
		$msgs += "Arguments: " + $allArgs
		$msgs += "Switches: " + $switches
		$msgs += "Log File: " + $gLogFile
		$msgs += ""
		$msgs += "___ STARTING WORK ___"
		$msgs += ""
		
		Foreach($msg in $msgs)
			{Write-Out $msg "white" 1}
	}

Function Throw-Warning($msg)
	{Write-Out $msg "magenta" 1}

Function Release-Ref ($ref)
	{
		#REF: code from: http://kentfinkle.com/PowershellAndExcel.aspx
		([System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$ref) -gt 0)
		[System.GC]::Collect()
		[System.GC]::WaitForPendingFinalizers() 
	}

Function Display-Array($arrArray,$intTabs,$verbosityLevel,$color)
	{
		If($color -eq $null)
			{$color = "white"}
		
		If($intTabs -eq $null -or $intTabs -le 0)
			{$intTabs = 0}
		If($verbosityLevel -eq $null -or $verbosityLevel -le 0)
			{$verbosityLevel = 2}
		
		#generate tabs
		$i = $null
		$i = 0
		While($i -lt $intTabs)
			{
				$strTabs += "`t"
				$i++
			}
		
		$msgs = $null
		$msgs = @()
		Foreach($strMember in $arrArray)
			{$msgs += $strTabs + "* " + ($strMember -replace("`t",""))}
		
		If($verbosityLevel -eq "4")
			{$color = "darkcyan"}
		
		$msg = $null
		Foreach($msg in $msgs)
			{Write-Out $msg $color $verbosityLevel}
	}

Function Display-HashTable($hshTable,$intTabs,$verbosityLevel,$color)
	{
		If($color -eq $null)
			{$color = "white"}
		
		If($intTabs -eq $null -or $intTabs -le 0)
			{$intTabs = 0}
		If($verbosityLevel -eq $null -or $verbosityLevel -le 0)
			{$verbosityLevel = 2}
		
		#generate tabs
		$i = $null
		$i = 0
		While($i -lt $intTabs)
			{
				$strTabs += "`t"
				$i++
			}
		
		$keys = $null
		$keys = $hshTable.Keys
		
		$msgs = $null
		$msgs = @()
		$msgs += $strTabs + "* Key, Value"
		Foreach($key in $keys)
			{$msgs += $strTabs + "* " + $key + ", " + $hshTable.Get_Item($key)}
		
		If($verbosityLevel -eq "4")
			{$color = "darkcyan"}
		
		$msg = $null
		Foreach($msg in $msgs)
			{Write-Out $msg $color $verbosityLevel}
	}

Function Run-RemoteCommand($server,$command)
	{
		$CS = Gwmi Win32_ComputerSystem -Comp "."
		$computer = $CS.Name
		If($computer -eq $server)
			{
				$msg = "ACTION`t`tRunning a local command."
				Write-Out $msg "darkgray" 4
			}
		Else
			{
				$msg = "ACTION`t`tRunning a remote command."
				Write-Out $msg "darkgray" 4
			}
		
		$msg = "INFO`t`t`tExpression: " + $command
		Write-Out $msg "darkgray" 4
		
		$strWMI = $null
		$strWMI = "\\" + $server + "\ROOT\CIMV2:Win32_Process"
		$objWin32Process = [WmiClass]$strWMI
		$objProcess = $objWin32Process.Create($command)
		$ID = $null
		$ID = $objProcess.ProcessID
		
		$msg = "INFO`t`t`tProcess ID on """ + $server + """: " + $ID
		Write-Out $msg "darkgray" 4
		$proc = $null
		
		#decide if we're on the remote system or not
		If($computer -eq $server)
			{
				#run get-process locally if we're already on the remote system.
				Do
				  {
				  	$proc = Get-Process -ID $ID -errorAction silentlyContinue
		    		If($proc -eq $null)
		    			{Break}
		    		Else
		    			{
		    				sleep -s 1
		    				$proc = $null
		    			}
				  }
				While($true)
			}
		Else
			{
				#run get-process remotely if we're not on the remote system.
				Do
				  {
				  	$proc = Get-Process -computername $server -ID $ID -errorAction silentlyContinue
		    		If($proc -eq $null)
		    			{Break}
		    		Else
		    			{
		    				sleep -s 1
		    				$proc = $null
		    			}
				  }
				While($true)
			}
		
	}


##
## STRING FORMATTING
##

Function Get-GroupMembers($strGroupDN)
	{
		#from: http://mow001.blogspot.com/2006/04/large-ad-queries-in-monad.html
		$objGroup = [adsi]("LDAP://" + $strGroupDN)
		$from = 0
		$all = $null
		$all = $false 
		$members = @() 
		while(! $all)
			{  
			 	 trap
			 	 	{
			 	 		set-variable -scope 1 -name all -value $true
			 	 		continue
			 	 	} 
			  $to = $from + 999 
			  $DS = New-Object DirectoryServices.DirectorySearcher($objGroup,"(objectClass=*)","member;range=$from-$to",'Base') 
			  $members += $ds.findall() | foreach {$_.properties | foreach {$_.item($_.PropertyNames -like 'member;*')}} 
			  $from += 1000
			  #Write-Host -f green -nonewline "."
			} 
		Return $members
	}

Function Sanitize-GroupCN($groupCN)
	{
		If($groupCN -like "*  *")
			{
				$msg = "ACTION`t`tConforming group name by replacing all ""  "" with "" ""."
				Write-Out $msg "darkcyan" 4
				While($groupCN -like "*  *")
					{$groupCN = $groupCN.replace("  "," ")}
			}
		Return $groupCN
	}

Function Parse-CSVStringToArray($strCSVRow)
	{
		#fixes the problem when you split @("one","""two,three""","four") -> One,"two,three",four
		$arrCSVRow = $strCSVRow.Split(",")
		$arrNewCSVRow = @()
		$i = 0
		$intCSVRows = $arrCSVRow.count
		While($i -le $intCSVRows)
			{
				#if the member has a "
				$member = $arrCSVRow[$i]
				If($member -like """*")
					{
						#take the " off
						$member1 = $null
						$member1 = $member.SubString(1)
						$strReplacementMember = $member1
						$i++
						#get next members
						$blnStop = $false
						While($blnStop -eq $false)
							{
								[string]$nextMember = $arrCSVRow[$i]
								#write-host -f green "nextmember: $nextmember"
								If($nextMember -like "*""")
									{
										$nextMember = $nextMember.Substring(0,($nextMember.length - 1))
										$blnStop = $true
									}
								Else
									{}
								$strReplacementMember += "," + $nextMember
								$i++
							}
						$strReplacementMember = $strReplacementMember.TrimEnd("""")
						
						$arrNewCSVRow += $strReplacementMember
					}
				ElseIf($member -like "*""")
					{}
				Else
					{
						$arrNewCSVRow += $member
						$i++
					}
			}
		
		$OFC = ","
		[string]$strNewCSVRow = $arrNewCSVRow
		Return $arrNewCSVRow
	}

Function Find-FileType($filename) #ECC
	{
		$failFunction = $false
		#Just a simple extension check
		$filetype = $false
		If(($filename.substring($filename.length - 4,4) -eq "xlsx"))
			{$filetype = "xlsx"}
		ElseIf(($filename.substring($filename.length - 3,3) -eq "csv"))
			{$filetype = "csv"}
		Else
			{$failFunction = $true}
		
		#Error Checking
		If($failFunction -eq $false)
			{Return $filetype}
		Else
			{Return $false}
	}

Function Check-StringAgainstRegex($string,$regex)
	{
		If($string -notmatch $regex)
			{$results = $false}
		Else
			{$results = $true}
		Return $results
	}

Function Parse-MemberOfHashToArray($hshUserInfo)
	{
		$results = $false
		$keys = $hshUserInfo.Keys
		If($keys -contains "memberof")
			{
				$memberOf = $hshUserInfo.Get_Item("memberof")
				If($memberOf -eq $null -or $memberOf -match "^[ \s]+" -or $memberOf -eq "")
					{$results = $false}
				Else
					{
						$groups = $memberOf.Split(",")
						If($groups -is [array])
							{$results = $groups}
						Else
							{
								$groups = @()
								$memberOf = $memberOf.TrimStart()
								$memberOf = $memberOf.TrimEnd()
								$groups += $memberOf
								$results = $groups
							}
					}				
			}
		Else
			{$results = $false}
		
		#Write-Host -f yellow "parse returning: $results"
		Return $results
	}

Function Convert-UNCPathToSharePath($folder,$server)
	{
		If($server -eq $null)
			{
				$server = Read-Variable "fileserver"
			}
		
		[array]$arrSplitFolder = $folder.Split("\")
		$path_Server = $arrSplitFolder[2]
		If($server -ne $path_Server)
			{$retval = $folder}
		Else
			{
				$sharename = $arrSplitFolder[3]
				$sharePath = Get-SharePath $shareName $server
				$sharePath = Trim-TrailingSlash $sharePath
				If($sharePath -eq $false)
					{$retval = $folder}
				Else
					{
						$pathToReplace = "\\" + $server + "\" + $sharename
						$partialPath = $folder -replace(([regex]::Escape($pathToReplace)),"")
						
						$retval = $sharePath + $partialPath
					}
			}
		Return $retval
	}

Function Convert-SharePathtoUNCPath($sharePath,$server)
	{
		If($server -eq $null)
			{
				$server = Read-Variable "fileserver"
			}
		#turns a local path into a UNC.
		#e.g. sharepath = C:\mount\groups0\data\computer_support
		 # retval = \\winfs\c$\mount\groups0\data\computer_support
		 # note: this (f) never returns a trailing slash
		[array]$arrSplitFolder = $sharePath.Split("\")
		If($arrSplitFolder[0] -like "*:")
			{
				#arrSplitFolder = C: mount groups0 data computer_support
				#need to build \\winfs\
				$fileServer = $server
				$fsPath = "\\" + $fileServer + "\"
				
				#need to get rid of the :
				$driveLetter = $arrSplitFolder[0] -replace("\:","$")
				$arrSplitFolder[0] = $driveLetter
				$strPath = $null
				$arrSplitFolder | %{If($_ -ne ""){$strPath += ($_ + "\")}}
				$strNewPath = $fsPath + $strPath
				$strFinalNewPath = Trim-TrailingSlash $strNewPath
				$retval = $strFinalNewPath
			}
		Else
			{$retval = $null}
		
		Return $retval
	}

Function Trim-OneFolderLevel($targetPath)
	{
		#returns _without_ a trailing slash
		### HACK ALERT!!!
		$targetPath = Trim-TrailingSlash $targetPAth
		### END HACK ALERT!!!
		$arrTargetPath = $null
		$arrTargetPath = $targetPath.Split("\")
		$intTargetPathCount = $null
		$intTargetPathCount = $arrTargetPath.Count
		$intNewPathCount = $null
		$intNewPathCount = $intTargetPathCount - 1
		
		$strNewPath = $null
		$i = 0
		Do
			{
				#this is to remove the trailing slash
				If($i -ge $intNewPathCount - 1)
					{$strNewPath += $arrTargetPath[$i]}
				Else
					{
						$strNewPath += $arrTargetPath[$i]
						$strNewPath += "\"
					}
				$i++
			}
		Until($i -ge $intNewPathCount)
		
		Return $strNewPath
	}

Function Add-TrailingSlash($path)
	{
		If(($path.substring(($path.length - 1),1)) -eq "\")
			{}
		Else
			{$path += "\"}
		Return $path
	}

Function Trim-TrailingSlash($path)
	{
		$retval = $path.TrimEnd("\")
		Return $retval
	}


##
## ACTIVE DIRECTORY
##

Function Put-LDAPAttribute($objUser,$attrName,$attrValue)
	{
		Trap{}
		$objUser.Put($attrName,$attrValue)
		$objUser.SetInfo()
	}

Function Check-IsDNAvailable($dn) #Skip ECC
	{
		$searchRoot = [ADSI]''
		$searcher = new-object System.DirectoryServices.DirectorySearcher($searchRoot)
		$searcher.filter = "(&(objectClass=*)(distinguishedName=" + $dn + "))"
		$searchResults = $searcher.findall()
		
		If($searchResults.count -lt 1)
			{$results = $true}
		Else
			{$results = $false}
		
		$searchResults.Dispose()
		$searcher.Dispose()
		$searchResults = $null
		$searcher = $null
		
		Return $results
	}

Function Check-IsUserWebOnly($objUser)
	{
		$blnWebOnly = $null
		$blnWebOnly = $false
		
		$strUserDN = $null
		$strUserDN = Pull-LDAPAttribute $objUser "distinguishedName"
		##ECC needed
		
		$strWebOnlyGroupCN = $null
		$strWebOnlyGroupCN = Read-Variable "WebOnlyGroupCN"
		$strWebOnlyGroupDN = $null
		$strWebOnlyGroupDN = Get-DNbyCN $strWebOnlyGroupCN
		#ECC needed
		
		#write-host -f yellow "DeBUG!`tuserDN: $strUserDN `tGroupDN: $strWebOnlyGroupDN"
		$blnWebOnly = Check-IsMemberOfGroup $strUserDN $strWebOnlyGroupDN
		
		$retval = $null
		$retval = $blnWebOnly
		Return $retval
	}

Function Get-DNbyCN($CN,$objectCategory)
	{
		$results = $null
		$root = [ADSI]''
		$searcher = new-object System.DirectoryServices.DirectorySearcher($root)
		Switch($objectCategory)
			{
				"group"
					{$searcher.filter = "(&(objectClass=group)(cn=" + $CN + "))"}
				"user"
					{$searcher.filter = "(&(objectClass=user)(cn=" + $CN + "))"}
				Default
					{$searcher.filter = "(&(|(objectClass=user)(objectClass=group))(cn=" + $CN + "))"}
			}
		
		$searchResults = $searcher.findall()
		
		If($searchResults.count -gt 0)
			{    
				$groupDN = $searchResults[0].path
				$groupDN = $groupDN.Substring(7)
				$results = $groupDN
			}
		Else
			{
				$results = $false
			}
		
		$searchResults.Dispose()
		$searcher.Dispose()
		$searchResults = $null
		$searcher = $null
		$root = $null
		
		Return $results
	}

Function Get-DNbySAMAccountName($sAMAccountName,$objectCategory) #ECC
	{
		$results = $null
		$root = [ADSI]''
		$searcher = new-object System.DirectoryServices.DirectorySearcher($root)
		Switch($objectCategory)
			{
				"group"
					{$searcher.filter = "(&(objectClass=group)(sAMAccountName=" + $sAMAccountName + "))"}
				"user"
					{$searcher.filter = "(&(objectClass=user)(sAMAccountName=" + $sAMAccountName + "))"}
				Default
					{$searcher.filter = "(&(|(objectClass=user)(objectClass=group))(sAMAccountName=" + $sAMAccountName + "))"}
			}
		$searchResults = $searcher.findall()
		
		If($searchResults.count -gt 0)
			{    
				$userDN = $searchResults[0].path
				$userDN = $userDN.Substring(7)
				$results = $userDN
			}
		Else
			{$results = $false}
		
		$searchResults.Dispose()
		$searcher.Dispose()
		$searchResults = $null
		$searcher = $null
		$root = $null
		
		Return $results
	}

Function Check-DNExists($dn)
	{
		#grab all grops with GID's
		$searchRoot = [ADSI]''
		$searcher = new-object System.DirectoryServices.DirectorySearcher($searchRoot)
		$searcher.filter = "(&(objectClass=*)(distinguishedName=" + $dn + "))"
		$searchResults = $searcher.findall()
		
		If($searchResults.count -lt 1)
			{$results = $false}
		Else
			{$results = $true}
		
		$searchResults.Dispose()
		$searcher.Dispose()
		$searchResults = $null
		$searcher = $null
		
		Return $results
	}

Function Pull-LDAPAttribute($objUser,$attribute)
	{
		trap{continue;}
		$objUserDN = $null
		$objUserDN = $objUser.Get("distinguishedName")
		$objUser = $null
		$objUser = [adsi]("LDAP://" + $objUserDN)
		$value = $null
		$value = $objUser.Get($attribute)
		If($value -eq "" -or $value -eq $null)
			{Return $null}
		Else
			{Return $value}
	}

Function Find-ExpirationDate($objUser)
	{
		$results = $null
		$sAMAccountName = Pull-LDAPAttribute $objUser "sAMAccountName"
		$objUser = Get-QADuser $sAMAccountName -IncludedProperties 'accountExpires' | select accountExpires
		$expirationDate = $objUser.accountExpires
		If($expirationDate -ne $null -and $expirationDate -ne $false)
			{
				$expirationDate = get-date (get-date $expirationDate -format "M/dd/yyyy")
				$results = $expirationDate
			}
		Else
			{$results = $null}
		
		$objUser = $null
		$expirationDate = $null
		
		Return $results
	}

Function Set-AccountExpirationDate($objUser,$date)
	{
		If($date -eq "unknown")
			{
				$warningMsg = "ERROR`tThis account should expire but doesn't."
				Throw-Warning $warningMsg
				$warningMsg = "ERROR`tPlease set an expiration date manually to continue work on this user."
				Throw-Warning $warningMsg
			}
		Else
			{
				$sAMAccountName = Pull-LDAPAttribute $objUser "sAMAccountName"
				Set-QADUser $sAMAccountName -accountexpires $date
			}
	}

Function Find-IsAccountClassOnly($objUser)
	{
		$results = $null
		$results = $true
		
		#If the user is a member of any groups that do not match "classes" or "class accounts"
		$groups = $null
		$groups = Pull-LDAPAttribute $objUser "memberOf"
		
		$objUserDN = $null
		$objUserDN = Pull-ldapAttribute $objUser "distinguishedName"
		$objGroupCN = $null
		$objGroupCN = Read-Variable "classAccountsQuotaGroupCN"
		$objGroupDN = Get-DNbyCN $objGroupCN "group"
		
		$classAccountsCheck = Check-IsMemberOfGroup $objUserDN $objGroupDN
		If($classAccountsCheck -eq $true)
			{
				Foreach($group in $groups)
					{
						If(`
									$group -like "*classes*" `
							-or $group -like ("*" + $objGroupCN + "*") `
							-or $group -like "ACL_*" `
							-or $group -like "RES_*"`
							)
							{}
						Else
							{$results = $false}
					}
			}
		Else
			{$results = $false}
		Return $results
	}

Function Get-AllUsersInOU($OUDN)
	{
		$results = $null
		$failThisFunction = $null
		$failThisFunction = $false
		
		$blnSourceExists = Check-DNExists $OUDN
		If($blnSourceExists -eq $false)
			{
				$msg = "Debug`t`tSourceOU does not exist: """ + $OUDN + """."
				Throw-Warning $msg
				$results = $false
				$failThisFunction = $true
			}
		
		If($failThisFunction -eq $false)
			{
				$ldapFilter = $null
				$ldapFilter = "(objectCategory=user)"
				
				# THIS CODE TOTALLY WORKS!!!
				$searchRoot = New-Object System.DirectoryServices.DirectoryEntry(("LDAP://" + $OUDN))
				$searcher = New-Object System.DirectoryServices.DirectorySearcher($searchRoot)
				$searcher.Filter = $ldapFilter
				$searcher.PageSize = 1000
				$searchResults = $null
				$searchResults = $searcher.FindAll()
				$intUsernames = 0
				$arrUsernames = $null
				$arrUsernames = @()
				Foreach($result in $searchResults)
					{
						$userPath = $null
						$userPath = $result.path
						$objUser = $null
						$objUser = [adsi]$userPath
						$sAMAccountName = $null
						$sAMAccountName = Pull-LDAPAttribute $objUser "sAMAccountName"
						$arrUsernames += $sAMAccountName
						$intUsernames++
						#give the user some indication that it's working.
						If(($intUsernames % 500) -eq 0)
							{write-host -f white "." -nonewline}
					}
				Write-Host -f white "`n"
				
				$results = $arrUsernames
				
				$searchResults.Dispose()
				$searcher.Dispose()
				$searchResults = $null
				$searcher = $null
				$adsGroupPath = $null
				$domainSuffix = $null
				$strGroupDN = $null
			}
		
		If($failThisFunction -eq $true)
			{$results = $false}
		Else
			{}
		
		Return $results
	}

Function Find-NextAvailableUID()
	{
		$failThisfunction = $null
		$failThisfunction = $false
		
		$msg = "Searching for the next available unix UID."
		Write-Host -f white $msg
		
		$UIDSearchNumber = $null
		$UIDSearchNumber = 99999
		$UIDStep = $null
		$UIDStep = 1000
		$UIDStepTwo = $null
		$UIDStepTwo = 20
		
		$blnStop = $null
		$blnStop = $false
		$blnUsersFound = $null
		$blnUsersFound  = $false
		
		#search for users with UID's greater than the start number
		While($blnStop -eq $false)
			{
				If($UIDSearchNumber -lt 0)
					{$UIDSearchNumber = 0}
				
				$strFilter = $null
				$strFilter = "(&(objectClass=user)(uidNumber>=" + $UIDSearchNumber + "))"
				#Write-host -f yellow "DEBUG`tstrFilter: $strFilter"
				
				$searchRoot = [ADSI]''
				$searcher = new-object System.DirectoryServices.DirectorySearcher($searchRoot)
				$searcher.filter = $strFilter
				$searchResults = $searcher.findall()
				
				$searchCount = $searchResults.Count
				#write-host -f yellow "DEBUG`tsearchCount: $searchCount"
				
				If($searchCount -gt 1)
					{
						If($blnUsersFound -eq $true)
							{
								$blnStop = $true
							}
						Else
							{
								$blnUsersFound = $true
								$UIDSearchNumber = $UIDSearchNumber + $UIDStep
								$UIDStep = $UIDStepTwo
							}
					}
				Else
					{
						$searchResults.Dispose()
						$searcher.Dispose()
						$searchResults = $null
						$searcher = $null
						If($UIDSearchNumber -eq 0)
							{
								$blnStop = $true
								$searchResults = $false
							}
						Else
							{$UIDSearchNumber = $UIDSearchNumber - $UIDStep}
					}
			}
		
		#work through search results looking at the uidNumbers
		If($searchResults -eq $false -or $searchCount -lt 1)
			{
				$msg = "Warning`tCould not find any users with UID's!"
				Throw-Warning $msg
				$failThisfunction = $true
			}
		Else
			{
				Foreach($user in $searchResults)
					{
						$userDN = $user.path
						$userDN = $userDN.Substring(7)
						$objUser = [adsi]("LDAP://" + $userDN)
						$sAMAccountName = Pull-LDAPAttribute $objUser "sAMAccountName"
						$uidNumber = Pull-LDAPAttribute $objUser "uidNumber"
						If($uidNumber -gt $currentHighestUID)
								{
									$thirdHighestUID = $secondHighestUID
									$secondHighestUID = $currentHighestUID
									$currentHighestUID = $uidNumber
								}
						$userDN = $null
					}
				$searchResults.Dispose()
				$searcher.Dispose()
				$searchResults = $null
				$searcher = $null	
			}
		
		If($failThisFunction -eq $true)
			{$retval = $false}
		Else
			{
				$nextAvailableUnixUID = $currentHighestUID + 1
				$arrUIDs = $null
				$arrUIDs = @()
				$arrUIDs += $thirdHighestUID
				$arrUIDs += $secondHighestUID
				$arrUIDs += $currentHighestUID
				
				Write-Host -f gray "Three current highest UID's:"
				Foreach($uid in $arrUIDs)
					{write-host -f gray "`t*unavailable (used) uid: $uid"}
				
				$retval = $nextAvailableUnixUID
				write-host -f cyan "Next available uid: $retval"
			}
		
		return $retval
	}

Function Check-UIDUnique($uid)
	{
		#grab all users with UID's
		$searchRoot = [ADSI]''
		$searcher = new-object System.DirectoryServices.DirectorySearcher($searchRoot)
		$searcher.filter = "(&(objectClass=user)(uidNumber=" + $uid + "))"
		$searchResults = $searcher.findall()
		
		if($searchResults.count -gt 0)
			{$results = $true}
		else
			{$results = $false}
		
		$searchResults.Dispose()
		$searcher.Dispose()
		$searchResults = $null
		$searcher = $null
		
		Return $results
	}

Function Check-gidExists($gidNumber) #done
	{
		#grab all grops with GID's
		$searchRoot = [ADSI]''
		$searcher = new-object System.DirectoryServices.DirectorySearcher($searchRoot)
		$searcher.filter = "(&(objectClass=group)(gidNumber=" + $gidNumber + "))"
		$searchResults = $searcher.findall()
		
		If($searchResults.count -lt 1)
			{$results = $false}
		Else
			{$results = $true}
			
		$searchResults.Dispose()
		$searcher.Dispose()
		$searchResults = $null
		$searcher = $null
			
		Return $results
	}

Function Find-RegexForAttribute($requiredAttribute)
	{
		Switch($requiredAttribute)
			{
				"sAMAccountName"
					{$regex = "^[a-z][-a-z_0-9.]{0,19}$"}
				"mail"
					{$regex = "^(\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b)?$"}
				"sn"
					{$regex = "^[a-z][\s'-a-z.]+$"}
				"givenName"
					{$regex = "^[a-z]+[\s'-a-z'.]*$"}
				"mail"
					{$regex = "^(\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b)?$"}
				"accountExpires" #mm/dd/yyyy
					{$regex = "^(([0]?[1-9]|1[012])[\/ \.]([0]?[1-9]|[12][0-9]|3[01])[\/ \.](19|20)\d\d)?$"}
				"telephoneNumber" # (###) ###-####
					{$regex = "^(\([0-9]{3}\)\s[0-9]{3}-[0-9]{4})?$"}
				"physicalDeliveryOfficeName" # LL####-??
					{$regex = "^([a-z][a-z][0-9]{3,4}[-a-z0-9]*)?$"}
				"uidNumber" #digits-only
					{$regex = "^([\d]{3,5})?$"}
				"gidNumber" #digits only
					{$regex = "^[\d][\d]*$"}
				"employeeID" #10 characters; digits-only
					{$regex = "^([\d]{10})?$"}
				
				Default
					{$regex = $false}
			}
		Return $regex
	}

Function Get-UACFlags($UAC)
	{
		#REF: http://bsonposh.com/archives/288
		#REF: http://www.eggheadcafe.com/software/aspnet/31909182/useraccountcontrol.aspx
		$flags = @()
		switch ($uac)
			{
				{($uac -bor 0x0002) -eq $uac} {$flags += "ACCOUNTDISABLE"}
				{($uac -bor 0x0008) -eq $uac} {$flags += "HOMEDIR_REQUIRED"}
				{($uac -bor 0x0010) -eq $uac} {$flags += "LOCKOUT"}
				{($uac -bor 0x0020) -eq $uac} {$flags += "PASSWD_NOTREQD"}
				{($uac -bor 0x0040) -eq $uac} {$flags += "PASSWD_CANT_CHANGE"}
				{($uac -bor 0x0080) -eq $uac} {$flags += "ENCRYPTED_TEXT_PWD_ALLOWED"}
				{($uac -bor 0x0100) -eq $uac} {$flags += "TEMP_DUPLICATE_ACCOUNT"}
				{($uac -bor 0x0200) -eq $uac} {$flags += "NORMAL_ACCOUNT"}
				{($uac -bor 0x0800) -eq $uac} {$flags += "INTERDOMAIN_TRUST_ACCOUNT"}
				{($uac -bor 0x1000) -eq $uac} {$flags += "WORKSTATION_TRUST_ACCOUNT"}
				{($uac -bor 0x2000) -eq $uac} {$flags += "SERVER_TRUST_ACCOUNT"}
				{($uac -bor 0x10000) -eq $uac} {$flags += "DONT_EXPIRE_PASSWORD"}
				{($uac -bor 0x20000) -eq $uac} {$flags += "MNS_LOGON_ACCOUNT"}
				{($uac -bor 0x40000) -eq $uac} {$flags += "SMARTCARD_REQUIRED"}
				{($uac -bor 0x80000) -eq $uac} {$flags += "TRUSTED_FOR_DELEGATION"}
				{($uac -bor 0x100000) -eq $uac} {$flags += "NOT_DELEGATED"}
				{($uac -bor 0x200000) -eq $uac} {$flags += "USE_DES_KEY_ONLY"}
				{($uac -bor 0x400000) -eq $uac} {$flags += "DONT_REQ_PREAUTH"}
				{($uac -bor 0x800000) -eq $uac} {$flags += "PASSWORD_EXPIRED"}
				{($uac -bor 0x1000000) -eq $uac} {$flags += "TRUSTED_TO_AUTH_FOR_DELEGATION"}
			}
			return $flags
	}

Function Get-UACFlagInt($flag)
	{
		#REF: http://bsonposh.com/archives/288
		#REF: http://www.eggheadcafe.com/software/aspnet/31909182/useraccountcontrol.aspx
		$intValue = $null
		
		switch ($flag)
			{
				"ACCOUNTDISABLE" {$intValue = 2}
				"HOMEDIR_REQUIRED" {$intValue = 8}
				"LOCKOUT" {$intValue = 16}
				"PASSWD_NOTREQD" {$intValue = 32}
				"PASSWD_CANT_CHANGE" {$intValue = 64}
				"ENCRYPTED_TEXT_PWD_ALLOWED" {$intValue = 128}
				"TEMP_DUPLICATE_ACCOUNT" {$intValue = 256}
				"NORMAL_ACCOUNT" {$intValue = 512}
				"INTERDOMAIN_TRUST_ACCOUNT" {$intValue = 2048}
				"WORKSTATION_TRUST_ACCOUNT" {$intValue = 4096}
				"SERVER_TRUST_ACCOUNT" {$intValue = 8192}
				"DONT_EXPIRE_PASSWORD" {$intValue = 65536}
				"MNS_LOGON_ACCOUNT" {$intValue = 131072}
				"SMARTCARD_REQUIRED" {$intValue = 262144}
				"TRUSTED_FOR_DELEGATION" {$intValue = 524288}
				"NOT_DELEGATED" {$intValue = 1048576}
				"USE_DES_KEY_ONLY" {$intValue = 2097152}
				"DONT_REQ_PREAUTH" {$intValue = 4194304}
				"PASSWORD_EXPIRED" {$intValue = 8388608}
				"TRUSTED_TO_AUTH_FOR_DELEGATION" {$intValue = 16777216}
			}
		Return $intValue
	}

Function Check-StringToInt($string)
	{
		$blnIntTestOK = $null
		$blnIntTestOK = $false
		
		If($string -match "[0123456789]$")
			{
				[int32]$intTest = $string
				$varType = $intTest.GetType().Name
				If($varType -eq "Int32")
					{$blnIntTestOK = $true}
				Else
					{
						$blnIntTestOK = $false
					}
			}
		
		Return $blnIntTestOK
	}

Function Check-IsUnixAccount($objUser)
	{
		$bUnixAccnt = $null
		$bUnixAccnt = $false
		$arrUnixAttributeList = Read-Variable "unixAttributeList"
		$arrUnixAttributeList | % {
			$curAttrib = $_
			$attrValue = $null
			$attrValue = Pull-LDAPAttribute $objUser $curAttrib
			If($attrValue -eq $null -or $attrValue -eq "" -or $attrValue -eq $false)
				{}
			Else
				{$bUnixAccnt = $true}
		}
		
		$results = $bUnixAccnt
		Return $results
	}

Function Check-DoesUserExist($sAMAccountName)
	{
		#grab all grops with GID's
		$searchRoot = [ADSI]''
		$searcher = new-object System.DirectoryServices.DirectorySearcher($searchRoot)
		$searcher.filter = "(&(objectClass=person)(sAMAccountName=" + $sAMAccountName + "))"
		$searchResults = $searcher.findall()
		
		If($searchResults.count -lt 1)
			{$results =  $false}
		Else
			{$results = $true}
		
		$searchResults.Dispose()
		$searcher.Dispose()
		$searchResults = $null
		$searcher = $null
		
		Return $results
	}

Function Check-DoesGroupExist($groupCN)
	{
		#grab all grops with GID's
		$searchRoot = [ADSI]''
		$searcher = new-object System.DirectoryServices.DirectorySearcher($searchRoot)
		$searcher.filter = "(&(objectClass=group)(CN=" + $groupCN + "))"
		$searchResults = $searcher.findall()
		
		If($searchResults.count -lt 1)
			{$results = $false}
		Else
			{$results = $true}
		
		$searchResults.Dispose()
		$searcher.Dispose()
		$searchResults = $null
		$searcher = $null
		
		Return $results
	}

Function Get-ACLWriteGroupCN($groupCN)
	{
		#prepare variables
		$groupCN_ProperCase = $null
		$groupCN_ProperCase = (Get-Culture).TextInfo.ToTitleCase($groupCN)
		$formattedGroupCN = $null
		$formattedGroupCN = $groupCN_ProperCase -replace("\s","")
		#build read group
		$strReadGroup = $null
		$strReadGroup = "ACL_" + $formattedGroupCN + "Share_AllowWrite"
		Return $strReadGroup
	}

Function Convert-DNtoCN-Local($DN)
	{
		$CN = $null
		$CN = ($DN.substring(3)).Split(",")[0]
		Return $CN
	}

Function Convert-SearchPathtoCN-Local($searchPath)
	{
		$cn = $null
		$cn = ($searchPath.substring(10)).Split(",")[0]
		Return $cn
	}

Function Get-ACLReadGroupCN($groupCN)
	{
		#prepare variables
		$groupCN_ProperCase = $null
		$groupCN_ProperCase = (Get-Culture).TextInfo.ToTitleCase($groupCN)
		$formattedGroupCN = $null
		$formattedGroupCN = $groupCN_ProperCase -replace("\s","")
		#build write group
		$strWriteGroup = $null
		$strWriteGroup = "ACL_" + $formattedGroupCN + "Share_AllowRead"
		Return $strWriteGroup
	}

Function Check-IsMemberOfGroup($strSourceDN,$strGroupDN)
	{
		$results = $null
		$results = $false
		$fail = $null
		$fail = $false
		
		$blnSourceExists = Check-DNExists $strSourceDN
		If($blnSourceExists -eq $false)
			{
				$results = $false
				$fail = $true
			}
		
		$blnGroupExists = Check-DNExists $strGroupDN
		If($blnSourceExists -eq $false)
			{
				$results = $false
				$fail = $true
			}
			
		If($fail -eq $false)
			{
				$ldapFilter = $null
				$ldapFilter = "(&(objectCategory=group)(member=" + $strSourceDN + "))"
				#write-host -f yellow "check-ismemberofgroup - ldapfilter: $ldapFilter"
				
				$strGroupDN = $strGroupDN.substring(3)
				# THIS CODE TOTALLY WORKS!!!
				$domainSuffix = Read-Variable "domainSuffix"
				$searchRoot = "LDAP://" + $domainSuffix
				$searcher = New-Object System.DirectoryServices.DirectorySearcher($searchRoot)
				$searcher.Filter = $ldapFilter
				$searcher.PageSize = 1000
				$searchResults = $null
				$searchResults = $searcher.FindAll()
				Foreach($result in $searchResults)
					{
						$resultDN = ($result.path).substring(10)
						If($resultDN -eq $strGroupDN)
							{
								$results = $true
								Break
							}
					}
				
				$searchResults.Dispose()
				$searcher.Dispose()
				$searchResults = $null
				$searcher = $null
				$adsGroupPath = $null
				$domainSuffix = $null
				$strGroupDN = $null
			}
		
		Return $results
	}

Function Check-GroupContainsGroups($groupCN)
	{
		$results = $null
		$results = $false
		
		$groupDN = $null
		$groupDN = Get-DNbyCN $groupCN "group"
		$objGroup = $null
		$objGroup = [ADSI]("LDAP://" + $groupDN)
		$members = $null
		$members = Pull-LDAPAttribute $objGroup "member"
		#$members = $members | Sort-Object
		$DN = $null
		$searchRoot = [ADSI]''
		$searcher = new-object System.DirectoryServices.DirectorySearcher($searchRoot)
		Foreach($DN in $members)
			{
				$searcher.filter = "(&(objectClass=group)(distinguishedName=" + $dn + "))"
				$searchResults = $searcher.findall()
				
				If($searchResults.count -lt 1)
					{}
				Else
					{$results = $true}
			}
		
		$searchResults.Dispose()
		$searcher.Dispose()
		$searchResults = $null
		$searcher = $null
		
		Return $results
	}

Function Create-Group($groupCN,$OU_DN)
	{
		$failThisFunction = $null
		$failThisFunction = $false
		$blnContinue = $true
		$blnContinue = $true
		
		#format groupCN (get rid of double spaces)
		$newGroupCN = Sanitize-GroupCN $groupCN
		If($newGroupCN -eq $false)
			{
				$warningMsg = "ERROR`t`tCould not format group CN properly."
				Throw-Warning $warningMsg
				$failThisFunction = $true
			}
		
		If($failThisFunction -eq $false)
			{
				$blnGroupExists = $null
				$blnGroupExists = Get-DNbyCN $groupCN "group"
				If($blnGroupExists -ne $false)
					{
						$msg = "Info`t`tThe group """ + $groupCN + """ already exists."
						Write-Out $msg "white" 2
						$continue = $false
					}
				Else
					{
						#check target OU existance
						If($failThisFunction -eq $false)
							{
								$blnOUExists = $null
								$blnOUExists = $false
								$blnOUExists = Check-DNExists $OU_DN
								If($blnOUExists -ne $true)
									{
										$warningMsg = "ERROR`t`tCould not find target OU DN """ + $OU_DN + """."
										Throw-Warning $warningMsg
										$failThisFunction = $true
									}
							}
						
						#check target OU objectCategory
						If($failThisFunction -eq $false)
							{
								$objOU = $null
								$objOU = [adsi]("LDAP://" + $OU_DN)
								$OU_OC = Pull-LDAPAttribute $objOU "objectCategory"
								If($OU_OC -notlike "*organizational-unit*")
									{
										$warningMsg = "ERROR`t`tThe target OU is not an organizational unit."
										Throw-Warning $warningMsg
										$warningMsg = "Info`t`tTarget OU: """ + $OU_DN + """."
										Throw-Warning $warningMsg
										$warningMsg = "Info`t`tTarget OU ObjectCategory: """ + $OU_OC + """."
										Throw-Warning $warningMsg
										$failThisFunction = $true
									}
							}
						
						#check proposed DN availability
						If($failThisFunction -eq $false)
							{
								$newGroupDN = "CN=" + $newGroupCN + "," + $OU_DN
								$blnGroupDNTaken = Check-DNExists $newGroupDN
								If($blnGroupDNTaken -eq $true)
									{
										$warningMsg = "Error`t`tThe proposed DN already exists """ + $newGroupDN + """."
										Throw-Warning $warningMsg
										$failThisFunction = $true
									}
							}
						
						#create the group
						If($failThisFunction -eq $false)
							{
								#create the group
								$objNewGroup = $null
								$objNewGroup = $objOU.Create("group",("cn=" + $newGroupCN))
								$objNewGroup.SetInfo()
							}
						
					}
			}
		
		$blnGroupCheck = Get-DNbyCN $newGroupCN "group"
		If($blnGroupCheck -eq $false)
			{$results = $false}
		Else
			{$results = $true}
			
		Return $results
	}

Function Create-ACLGroup($groupCN)
	{
		$failThisFunction = $null
		$failThisFunction = $false
		
		#format groupCN (get rid of double spaces)
		$newGroupCN = Sanitize-GroupCN $groupCN
		If($newGroupCN -eq $false)
			{
				$warningMsg = "ERROR`t`tCould not format group CN properly."
				Throw-Warning $warningMsg
				$failThisFunction = $true
			}
		
		$ACLGroupsOU = Read-Variable "CRGroupsOU"
		$blnCreateGroup = Create-Group $newGroupCN $ACLGroupsOU
		
		$results = $null
		$GroupDN = Get-DNbyCN $newGroupCN "group"
		If($groupDN -eq $false)
			{$results = $false}
		Else
			{$results = $true}
		Return $results
	}

Function Create-ClassGroup($groupCN)
	{
		$failThisFunction = $null
		$failThisFunction = $false
		
		#format groupCN (get rid of double spaces)
		$newGroupCN = Sanitize-GroupCN $groupCN
		If($newGroupCN -eq $false)
			{
				$warningMsg = "ERROR`t`tCould not format group CN properly."
				Throw-Warning $warningMsg
				$failThisFunction = $true
			}
		
		$studentGroupsOU = Read-Variable "studentGroupsOUDN"
		Create-Group $newGroupCN $studentGroupsOU
		
		$results = $null
		$groupDN = Get-DNbyCN $newGroupCN "group"
		If($groupDN -eq $false)
			{$results = $false}
		Else
			{$results = $true}
		Return $results
	}

Function Add-ToGroup($sourceDN, $groupDN)
	{
		$results = $null
		#Bind to the group
		
		If($groupDN -eq $false)
			{
				$warningMsg = "ERROR`tCannot add object to group; Group DNE: """ + $groupCN + """."
				Throw-Warning $warningMsg
				$failFunction = $true
			}
		Else
			{
				$objGroup = [adsi]("LDAP://" + $groupDN)
				$OC = Pull-LDAPAttribute $objGroup "objectCategory"
				If($OC -notlike "*group*")
					{
						$msg = "ERROR`t`tThe group specified is not actually a group!"
						Throw-Warning $msg
						$results = $false
					}
				Else
					{
						#Check to see if the user is already a member of the group
						$objGroupMember = Pull-LDAPAttribute $objGroup "member"
						$objSourceADObject = [adsi]("LDAP://" + $sourceDN)
						$objSourceMemberOf = Pull-LDAPAttribute $objSourceADObject "memberOf"
						If($objGroupMember -contains $sourceDN)
							{$results = $true}
						ElseIf($objSourceMemberOf -contains $groupDN)
							{$results = $true}
						Else
							{
								#Add the user to the group
								$objGroup.member.add($sourceDN) | Out-Null
								$objGroup.SetInfo()
								#Check to see if it worked
								$objGroupMember = Pull-LDAPAttribute $objGroup "member"
								$objSourceMemberOf = Pull-LDAPAttribute $objSourceADObject "memberOf"
								If($objGroupMember -contains $sourceDN)
									{$results = $true}
								ElseIf($objSourceMemberOf -contains $groupDN)
									{$results = $true}
								Else
									{$results = $false}
							}
					}
			}
		
		If($results -eq $null)
			{$results = $false}
		
		Return $results
	}

Function Remove-ElementFromArray($strElement,$arrArray)
	{
		$newArray = $null
		$newArray = @()
		Foreach($element in $arrArray)
			{
				If($element -eq $strElement)
					{}
				Else
					{$newArray += $element}
			}
		Return $newArray
	}

Function Remove-FromGroup($strSourceDN,$strGroupDN)
	{
		$failThisFunction = $null
		$failThisFunction = $false
		$results = $null
		$results = $false
		$blnSkipRemove = $null
		$blnSkipRemove = $false
		
		#check source\target DNs
		$blnSourceCheck = $null
		$blnSourceCheck = $false
		$blnSourceCheck = Check-DNExists $strSourceDN
		If($blnSourceCheck -eq $false)
			{
				$msg = "Error`t`t`tThe source DN """ + $strSourceDN + """ does not exist."
				Throw-Warning $msg
				$failThisFunction = $true
			}
		$blnTargetCheck = $null
		$blnTargetCheck = $false
		$blnTargetCheck = Check-DNExists $strGroupDN
		If($blnTargetCheck -eq $false)
			{
				$msg = "Error`t`t`tThe target group """ + $strTargetDN + """ does not exist."
				Throw-Warning $msg
				$failThisFunction = $true
			}
		
		#check to make sure the object is a member of the target group
		If($failThisFunction -eq $false)
			{
				$blnMemberCheck = $null
				$blnMemberCheck = $false
				$blnMemberCheck = Check-IsMemberOfGroup $strSourceDN $strGroupDN
				If($blnMemberCheck -eq $false)
					{
						$msg = "Info`t`t`tObject is already not a member of the group DN """ + $strGroupDN + """."
						Write-Out $msg "darkcyan" 4
						$results = $true
					}
				Else
					{
						$msg = "Action`t`t`tRemoving object from the group."
						Write-Out $msg "darkcyan" 4
						$objGroup = [adsi]("LDAP://" + $strGroupDN)
						$objGroup.Remove(("LDAP://" + $strSourceDN))
						$objGroup.SetInfo()
						
						#confirm
						$blnMemberCheck = $null
						$blnMemberCheck = $false
						$blnMemberCheck = Check-IsMemberOfGroup $strSourceDN $strGroupDN
						If($blnMemberCheck -eq $false)
							{
								$msg = "Info`t`t`tObject removed successfully."
								Write-Out $msg "darkcyan" 4
								$results = $true
							}
						Else
							{
								$msg = "Error`t`t`tCould not remove object from the group."
								Throw-Warning $msg
								$failThisFunction = $true
								$results = $false
							}
					}
			}
		
		If($failThisFunction -eq $true)
			{$results = $false}
		Else
			{}
		
		Return $results
	}

Function Pick-OU($strMode,$cn)
	{
		$failThisFunction = $null
		$failThisFunction = $false
		
		If($cn -eq $null -or $cn -eq "" -or $cn -eq $false)
			{
				$msg = "Error`t`tThe cn given wasn't valid: """ + $cn + """."
				Throw-Warning $msg
				$failThisFunction = $true
			}
		
		Switch($strMode)
			{
				"roaming-classes"
					{
						$OUs = Read-Variable "roamingClassesOrganizationalUnits"
					}
				"roaming"
					{
						$OUs = Read-Variable "roamingOrganizationalUnits"
					}
				"redirected"
					{
						$OUs = Read-Variable "redirectedOrganizationalUnits"
					}
#				"local"
#					{
#						$OUs = Read-Variable ""
#					}
				"web-classes"
					{
						$OUs = Read-Variable "WebOnlyClassesOrganizationalUnits"
					}
				"web"
					{
						$OUs = Read-Variable "WebOnlyOrganizationalUnits"
					}
				Default
					{
						$msg = "Error`t`tCould not choose DN of the type: """ + $strMode + """."
						Throw-Warning $msg
						$failThisFunction = $true
					}
			}
		
		If($failThisFunction -eq $false)
			{
				If($OUs -eq $null -or $OUs -eq $false -or $OUs -eq "")
					{
						$msg = "Error`t`tCould not parse the OUs read from the settings file for type """ + $strMode + """."
						Throw-Warning $msg
						$failThisFunction = $true
					}
				Else
					{
						$blnOUFree = $null
						$blnOUFree = $false
						$strOUFree = $null
						Foreach($OU in $OUs)
							{
								If($blnOUFree -eq $false)
									{
										$strTestDN = $null
										$strTestDN = "CN=" + $cn + "," + $OU
										$blnDNAvailable = $null
										$blnDNAvailable = $false
										$blnDNAvailable = Check-IsDNAvailable $strTestDN
										If($blnDNAvailable -eq $true)
											{
												$blnOUFree = $true
												$strOUFree = $OU
											}
									}
							}
						If($blnOUFree -eq $false -or $blnOUFree -eq $null)
							{$retval = $false}
						Else
							{$retval = $strOUFree}
					}
			}
		
		If($failThisFunction -eq $true)
			{
				$retval = $false
			}	
		
		Return $retval
	}

Function Move-UserToOU($objUser,$targetOUDN)
	{
		$failThisFunction = $null
		$failThisFunction = $false
		
		#Verify target OU
		$blnTargetOUExists = $null
		$blnTargetOUExists = Check-DNExists $targetOUDN
		If($blnTargetOUExists -eq $true)
			{
				$msg = "INFO`t`tTarget OU Verified """ + $targetOUDN + """."
				Write-Out $msg "darkcyan" 4
			}
		Else
			{
				$warningMsg = "ERROR`t`tTarget OU does not exist """ + $targetOUDN + """."
				Throw-Warning $warningMsg
				$failThisFunction = $true
			}
		
		#Verify target displayname
		If($failThisFunction -eq $false)
			{
				$cn = $null
				$cn = Pull-LDAPAttribute $objUser "cn"
				
				$newDN = $null
				$newDN = "CN=" + $cn + "," + $targetOUDN
				$blnTargetDisplayNameValid = $null
				$blnTargetDisplayNameValid = Check-DNExists $newDN
				If($blnTargetDisplayNameValid -eq $false)
					{
						$msg = "INFO`t`tTarget DN is valid """ + $newDN + """."
						Write-Out $msg "darkcyan" 4
					}
				Else
					{
						$warningMsg = "ERROR`t`tTarget DN is invalid """ + $newDN + """."
						Throw-Warning $warningMsg
						$failThisFunction = $true
					}
			}
		
		#move the user
		$sAMAccountName = $null
		$sAMAccountName = Pull-LDAPAttribute $objUser "sAMAccountName"
		If($failThisFunction -eq $false)
			{
				$msg = "ACTION`t`tMoving user to target OU."
				Write-Out $msg "darkcyan" 4
				#REF: http://stackoverflow.com/questions/76325/move-active-directory-group-to-another-ou-using-powershell
				$objSource = $objUser
				$objDestination = [ADSI]("LDAP://" + $targetOUDN)
				$objSource.PSBase.MoveTo($objDestination)
			}
		
		#ECC
		If($failThisFunction -eq $false)
			{
				$results = $false
				$i = 0
				While($i -lt 10)
					{
						$objDN = $null
						$objDN = Get-DNbySAMAccountName $sAMAccountName
						If($objDN -eq $newDN)
							{
								$results = $true
								Break
							}
						Else
							{
								Sleep -s 1
								$i++
							}
					}
			}
		
		If($failThisFunction -eq $true)
			{$results = $false}
		Else
			{}
		
		Return $results
	}

Function Find-OSVersion($strRemoteComputer)
	{
		$retval = $null
		
		$computer = $strRemoteComputer
		$class = "Win32_OperatingSystem"
		$ea = "silentlyContinue"
		$wmiOS = Run-GWMI $computer $class $ea
		
		If($wmiOS -eq $null -or $wmiOS -eq "")
			{$retval = $false}
		Else
			{
				$strOSVersion = $wmiOS.Version
				If($strOSVersion -eq $null -or $strOSVersion -eq "")
					{$retval = $null}
				Else
					{$retval = $strOSVersion}
			}
		Return $retval
	}

Function Run-GWMI($computer,$class,$ea)
	{
		trap{continue;}
		$objWMI = $null
		$objWMI = gwmi -computername $computer -class $class -ea $ea
		Return $objWMI
	}
	
Function Export-LDIFRecord($DN)
{
	#GetUsername
	$objUser = $null
	$objUser = [adsi]("LDAP://" + $DN)
	$uName = Pull-LDAPAttribute $objUser "sAMAccountName"
	
	#Generate Path
	$ldifPath = Read-Variable "pathToLdifArchives"
	$ldifPath = (Trim-TrailingSlash $ldifpath) + "\"
	$path = $ldifPath + "ldif_" + $uName + ".ldif"
	$pathvalid = test-path $path
	#Set Path to not overwrite old archives
	if($pathvalid -eq $true) 
	{
		$i = 0
		$path = $ldifPath + "ldif_" + $uName + "(" + $i + ").ldif"
		$pathvalid = test-path $path
		while($pathvalid) 
		{
			$i++
			$path = $ldifPath + "ldif_" + $uName + "(" + $i + ").ldif"
			$pathvalid = test-path $path
		}
	}
	
	$filter = "(sAMAccountName=" + $uName + ")"
	
	#Export Record
	ldifde -f $path -r $filter
	
}
Function Verify-LDIFRecord($DN)
{
	#BindToUser
	$objUser = $null
	$objUser = [adsi]("LDAP://" + $DN)
	$sAMAccountName = Pull-LDAPAttribute $objUser "sAMAccountName"
	$givenName = Pull-LDAPAttribute $objUser "givenName"
	$sn = Pull-LDAPAttribute $objUser "sn"
	#Find Most Recent Archive
	$ldifPath = Read-Variable "pathToLdifArchives"
	$ldifPath = (Trim-TrailingSlash $ldifpath) + "\"
	$path = $ldifPath + "ldif_" + $sAMAccountName + ".ldif"
	$pathvalid = test-path $path
	if($pathvalid -eq $true) 
	{
		$i = 0
		$nextPath = $ldifPath + "ldif_" + $sAMAccountName + "(" + $i + ").ldif"
		$pathvalid = test-path $nextPath
		while($pathvalid) 
		{
			$path = $nextPath
			$i++
			$nextPath = $ldifPath + "ldif_" + $sAMAccountName + "(" + $i + ").ldif"
			$pathvalid = test-path $nextPath
		}
		#Load Record
		$ldifRecord = Get-Content $path
		#Check sn, givenName, and sAMAccountName in LDIF vs AD
		foreach ($record in $ldifRecord)
		{
			if($record.StartsWith("sn:") -eq $true)
			{
				if($record.Substring(4) -ne $sn.ToString())
				{
					$msg = "Error: " + $record + " does not match " + $sn.ToString()
					Throw-Warning $msg
					$failThisFunction = $true
				}
			} elseif($record.StartsWith("givenName:")) {
				if($record.Substring(11) -ne $givenName.ToString())
				{
					$msg = "Error: " + $record + " does not match " + $givenName.ToString()
					Throw-Warning $msg
					$failThisFunction = $true
				}
			} elseif($record.StartsWith("sAMAccountName:")) {
				if($record.Substring(16) -ne $sAMAccountName.ToString())
				{
					$msg = "Error: " + $record + " does not match " + $sAMAccountName.ToString()
					Throw-Warning $msg
					$failThisFunction = $true
				}
			}
		}	
	} else { #If Could not find LDIF, Throw Error
		$msg = "Error: Could not find ldif record at " + $path
		Throw-Warning $msg
		$failThisFunction = $true
	}
	
	#Check if function should fail and exit appropriately
	If($failFunction -eq $true)
	{
		$warningMsg = "ERROR`tFailing the script"
		Throw-Warning $warningMsg
		Return $false
	}
	Else
	{Return $true}

}