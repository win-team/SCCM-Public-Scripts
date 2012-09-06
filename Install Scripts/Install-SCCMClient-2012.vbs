'Install-SCCMClient.vbs
on error resume next

Dim currentVer
currentVer = "5.00.7711.0000"

'Init common variables
Dim wshShell
Dim objFileSystem
Set wshShell = wscript.CreateObject("wscript.Shell")
Set objFileSystem = CreateObject("scripting.FileSystemObject")

'Main Flow
If CheckSCCM = False Then
	InstallSCCMAgent
ElseIf CheckSCCMVersion < currentVer Then
	InstallSCCMAgent
End If

'Functions
Function InstallSCCMAgent
	Dim strRunString
	strRunString = "\\dc1\NETLOGON\deployment\SCCM2012\ccmsetup.exe SMSSITECODE=CHM RESETKEYINFORMATION=TRUE"
	wshShell.Run strRunString, 1, true
End Function

Function CheckSCCM
	Dim agentInstalled
	agentInstalled = True
	'msgbox "checking to see if agent is installed."
	If Not objFileSystem.FileExists("C:\Windows\System32\CCM\CcmExec.exe") Then
		'msgbox "did not find C:\Windows\System32\CCM"
		If Not objFileSystem.FileExists("C:\Windows\Syswow64\CCM\CcmExec.exe") Then
			agentInstalled = False
			'msgbox "did not find C:\Windows\Syswow64\CCM"
		End If
	End If
	'If agentInstalled = True Then msgbox "found SCCM Client"
	CheckSCCM = agentInstalled
End Function

Function CheckSCCMVersion
	Dim strComputer, objWMIService, objItem, colItems
	strComputer = "."
	
	'WMI Connection
	Set objWMIService = GetObject("winmgmts:\\.\root\ccm")
	Set colItems = objWMIService.ExecQuery("Select * from CCM_InstalledComponent")

	maxVer = "0"

	For Each objItem in colItems
	thisVer = objItem.version
	If thisVer > maxVer Then
		maxVer = thisVer
	End If

	Next
		CheckSCCMVersion = maxVer
End Function