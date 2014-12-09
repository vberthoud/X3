# Author: 		Bob Dealamter
# Date: 		12/09/2014
# Description: 	Return the last accessed time stamp from the local copy of the executed Sage ERP X3 report. 
#				This allows you to know who is running what reports, and at what time.
#
# Caveats:		In order for last accessed date to be accurate you must set the following registry key 
# 				HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem
# 				Set the NtfsDisableLastAccessUpdate = Hexadecimal value of 0
# 				In addition, the PC must be rebooted

$ErrorActionPreference = "Stop"
function CheckRegKey{
	$hive = [Microsoft.Win32.Registry]::LocalMachine
	$key = $hive.OpenSubKey("SYSTEM\CurrentControlSet\Control\FileSystem")
	$output = $key.GetValue("NtfsDisableLastAccessUpdate")
	
	if ($output -eq 0)
	{
		return $true
	}
	else
	{
		# Results of last accessed registry key cannot be trusted
		return $false
	}
}

try{
	#Check the registry to see that the value is correct
	$regKeyValue = CheckRegKey
	if ($regKeyValue -eq $false)
	{
		Write-Host "The registry value for 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem\NtfsDisableLastAccessUpdate' is not set to 0. Results cannot be trusted"
		Write-Host "Terminating early"
		Break
	}
	
	# Set this property to whatever output location you'd like
	$myPath = "C:\Temp\" 
	
	$computerName = Get-content env:computername 
	$userName = Get-Content env:username
	$fileName = $computerName + "-" + $userName + "-" + "LastAccessedDateOfSageReports.csv"
	$fullPath = $myPath + $fileName

	Get-ChildItem -Path "C:\ProgramData\Sage\Safe X3 Client\V1\Data\X3_x3v6stdp26pd_1806\ENG\Report" | select name, *time | Export-Csv -Path $FileName -Encoding ascii -NoTypeInformation
	$HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
	$HOST.UI.RawUI.Flushinputbuffer()
}
catch{
	$_|select -ExpandProperty invocationinfo
	Write-Host "Error: $Error[0].  Terminating execution."
	$Error.Clear()	
}