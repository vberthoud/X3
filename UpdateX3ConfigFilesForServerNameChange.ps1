#Author: Bob Delamater
#Date: 10/02/2013
#Description: Server name change scripted out
# 1. Find reference in registry to current ADXADMIN path, then alter the xml files
# 2. 

$ErrorActionPreference = "Stop"
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

function Edit-XmlNodes {
param (
	[string] $filePath = $(throw "file path is a required parameter"),
    [string] $xpath = $(throw "xpath is a required parameter"),
    [string] $value = $(throw "value is a required parameter"),
    [bool] $condition = $true
)    
	
	# Does this XML file exist?
	if (DoesFileExist $filePath -eq $true)
		{
		Write-Host "Handling " $filePath
		$xml = [xml](Get-Content $filePath)
	    if ($condition -eq $true) {
	        $nodes = $xml.SelectNodes($xpath)
	         
	        foreach ($node in $nodes) {
	            if ($node -ne $null) {
	                if ($node.NodeType -eq "Element") {
	                    $node.InnerXml = $value
	                }
	                else {
	                    $node.Value = $value
	                }
	            }
	        }
	    }
		
		$xml.Save($filePath) 
	}
	
	CleanUp
}

#Set The System DSN for the machine
# You must know the DSN name before calling this
# Your $SystemDsnValue must be the name of the SQL Instance. Example: computerName\X3V6
function SetSystemDSNForDBConnection($ServerInstanceName)
{
	# Backup the existing registry entries first
	# This backup will capture all the system DSNs that were made. 
	#	Example: More than one solution in your X3 admin console? 
	#	This will capture each system DSN created
	$appDataPath = Get-Childitem env:APPDATA | %{ $_.Value }
	$longKeyName = "HKLM\SOFTWARE\ODBC\ODBC.INI"
	$backupLocation = "$appDataPath\systemDsn.reg"
	Reg export ""$longKeyName"" ""$backupLocation"" /y
	
	Write-Host "System DSNs registry values backed up to ""$backupLocation"""
	
	foreach($someAdonixKey in Get-ChildItem "HKLM:\SOFTWARE\Adonix\X3RUNTIME" -Recurse -ErrorAction SilentlyContinue)
	{
		#$itemProperty = (Get-ItemProperty -Path $someAdonixKey -ErrorAction SilentlyContinue -Name DATASOURCE).DATASOURCE 
		
		$mySubKey = $someAdonixKey| Split-Path -Leaf
		$hive = [Microsoft.Win32.Registry]::LocalMachine
		$key = $hive.OpenSubKey("SOFTWARE\Adonix\X3RUNTIME\$mySubKey")			
		$datasource = $key.GetValue("DATASOURCE")
		
		if ( ($datasource -ne $null) -or ($datasource -eq "") )	
		{
			Set-ItemProperty "HKLM:\SOFTWARE\ODBC\ODBC.INI\$mySubKey" -Name Server -Value "$ServerInstanceName"
		}
	}
	
	# Update the registry entry with the new server instance name
	
}

function Set-Config( $file, $key, $value )
{
	if (OSHasRobocopy -eq $true)
	{
		#backup the env.bat file
		$path = Get-ChildItem $file
		$backupFilePath = $path.DirectoryName 
		Robocopy $backupFilePath $backupFilePath"\bak" "env.bat"
		
	    $regreplace = $("(?<=$key).*?=.*")
	    $regvalue = $(" = " + $value)
	    if (([regex]::Match((Get-Content $file),$regreplace)).success) {
	        (Get-Content $file) `
	            |Foreach-Object { [regex]::Replace($_,$regreplace,$regvalue)
	         } | Set-Content $file
	    } else {
	        Add-Content -Path $file -Value $("`n" + $key + " = " + $value)          
	    }
	}
}


function DoesFileExist([string]$fullPathName)
{
	if(Test-Path $fullPathName)
	{
		
		return $true
	}
	
	else
	{
		Write-Host "File '$fullPathname' does not exist. Skipping this configuration file"
		return $false
	}

}
 
function GetADXInstallsPath{
	$key = 'HKLM:\Software\Adonix\X3RUNTIME\ADXADMIN'
	$ADXDIRPath = (Get-ItemProperty -Path $key -Name ADXDIR).ADXDIR
	if (($ADXDIRPath -eq $null) -or ($ADXDIRPath -eq ""))
	{
		Write-Host "The HKLM\Software\Adonix\X3RUNTIME\ADXADMIN was not found on this machine. Terminating execution of this script"
		Break
	}
	return $ADXDIRPath
	
}

#$action: $true = start service, $false = stop service
function HandleService([string]$strService, [string]$strComputer, [Boolean]$action){

$strClass = "win32_service"
$objWmiService = Get-Wmiobject -Class $strClass -computer $strComputer `
  -filter "name = '$strService'"
  
  switch ($action)
  {
  	$false
	{
		if( $objWMIService.Acceptstop )
		 { 
		  Write-Host "stopping the $strService service now ..." 
		  $rtn = $objWMIService.stopService()
		  Switch ($rtn.returnvalue) 
		  { 
		   0 { Write-Host -foregroundcolor green "$strService on $strComputer stopped" }
		   2 { Write-Host -foregroundcolor red "$strService service on $strComputer reports" `
		       " access denied" }
		   5 { Write-Host -ForegroundColor red "$strService service on $strComputer cannot" `
		       " accept control at this time" }
		   10 { Write-Host -ForegroundColor red "$strService service on $strComputer is already" `
		         " stopped" }
		   DEFAULT { Write-Host -ForegroundColor red "$strService service on $strComputer reports" `
		             " ERROR $($rtn.returnValue)" }
		  }
		 }
		ELSE
		 { 
		  Write-Host "$strService on $strComputer will not accept a stop request"
		 }		
	}
	
	$true
	{
		#$rtn = Start-Service $objWmiService.Name
		
		$rtnStartService = $objWMIService.StartService()
		
		Switch ($rtnStartService.retrunvalue)
		{
		   0 { Write-Host -foregroundcolor green "started" }
		   2 { Write-Host -foregroundcolor red "$strService service on $strComputer reports" `
		       " access denied" }
		   5 { Write-Host -ForegroundColor red "$strService service on $strComputer cannot" `
		       " accept control at this time" }
		   10 { Write-Host -ForegroundColor red "$strService service on $strComputer is already" `
		         "started" }
		   #DEFAULT { Write-Host -ForegroundColor red "$strService service on $strComputer reports" `
		   #          " ERROR $($rtn.returnValue)" }
		}
	}
  }
}

# <file><foo attribute="bar" attribute2="bar" attribute3="bar" /></file>

function Backup([string]$fromPath, [string]$toFolder)
{
	if(Test-Path $toFolder)
	{
		Write-Host "Folder patch $toFolder already exists. Copy aborted. Script aborted"
		break
	}
	else
	{
		#Copy-Item $fromFolder -Destination $toFolder 
		robocopy $fromPath $toFolder /E
	}
}

function CleanUp{

	$xml = $null
	$myFile = $null
	
}

function Get-FileContent($flatFileName)
{
	[Regex]$patt = '(?<=\s*)\S+(?=\s*(;|$))'
	
	foreach ($line in Get-Content $flatFileName -ReadCount 0) {
	 $sqlServer = Invoke-Expression ('@{' + ($line -replace $patt,'"$0"') + '}')
	 $sqlHostName = $sqlServer.hostName
	 $sqlInstanceName = $sqlServer.instanceName
}

}


Function OSHasRobocopy
{
	$majorVersion = [System.Environment]::OSVersion.Version.Major
	$minorVersion = [System.Environment]::OSVersion.Version.Minor
	$buildNumber = [System.Environment]::OSVersion.Version.Build
	$revNumber = [System.Environment]::OSVersion.Version.Revision

	# Valid operating systems that Robocopy exists on
	# http://technet.microsoft.com/en-us/library/cc733145.aspx

	#Operating System Build Numbers
	# http://msdn.microsoft.com/en-us/library/windows/desktop/ms724832(v=vs.85).aspx

	# Windows 7 And Windows Server 2008 R2
	If ($majorVersion -eq 6 -and $minorVersion -eq 1)
	{
		return $true
	}

	#Windows 8
	If ($majorVersion -eq 6 -and $minorVersion -eq 2)
	{
		return $true
	}

	# Windows Server 2008
	If ($majorVersion -eq 6 -and $minorVersion -eq 0)
	{
		return $true
	}

	# Windows Server 2012
	If ($majorVersion -eq 6 -and $minorVersion -eq 3)
	{
		return $true
	}

	Return $false
}

function HandleX3Services($action)
{
	#X3
	HandleService "X3V6PRM" "Localhost" $action
	HandleService "X3V6STD" "Localhost" $action

	#SQL
	HandleService "SQLBrowser" "Localhost" $action
	HandleService "SQLAgent`$X3V6" "Localhost" $action
	HandleService "MSSQL`$X3V6" "Localhost" $action
	

	#Apache And Tomcat
	HandleService "Apache2.2" "Localhost" $false
	HandleService "SageX3_WEB_apachehttpd_X3V6PRMWEB" "Localhost" $action
	HandleService "SageX3_WEB_apachetomcat_X3V6PRMWEB" "Localhost" $action

	#Print Server
	HandleService "Safe_X3_SE_V1_DEFAULT" "Localhost" $action

	#Business Objects

	#Java Server
	HandleService "SageX3_JAV_coreserver_X3V6STDJAV" "Localhost" $action

	#ADXADMIN
	HandleService "ADXADMIN" "Localhost" $action
}

Function Get-SQLInstance {
 
    param ([string]$ComputerName = $env:COMPUTERNAME)
 	$fullSQLServerInstanceName = ""
    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
    $regKey= $reg.OpenSubKey("SOFTWARE\\Microsoft\\Microsoft SQL Server\\Instance Names\\SQL" )
	
	# Only return the first instance in the list
    foreach($valueName in $regKey.GetValueNames())
	{
		$fullSQLServerInstanceName = $ComputerName + "\$valueName"
		return $fullSQLServerInstanceName 
	}
}

try{
	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
	
	$okToProceed = [System.Windows.Forms.MessageBox]::Show("This procedure will make changes to your X3 admin console. The changes are permanant with no rollback. Please make a backup before proceeding. Is it ok to proceed?", "Sage ERP X3: Ok To Proceed?", 4)
	if ($okToProceed -eq "No")
	{
		#Terminate execution of the script, DO NOT PROCEED ANY FURTHER
		Break
	}
	
	#Set Up File Location
	$baseADXInstallPathInstDir = GetADXInstallsPath
	$baseADXInstallPathInstDir += "\inst"
	$randNumForFileSuffix = Get-Random -Minimum 1 -Maximum 999999
	
	$SystemDrive = [System.Environment]::GetEnvironmentVariable("SystemDrive")
	
	#Backup existing installation as a backup
	if (OSHasRobocopy -eq $true)
	{
		Write-Host "Backing up configuration files to: $SystemDrive\ADXINSTALLBACKUP\fullBackup_$randNumForFileSuffix"
		Backup $baseADXInstallPathInstDir "$SystemDrive\ADXINSTALLBACKUP\fullBackup_$randNumForFileSuffix"
	}
	else
	{
		$okToProceedStill = [System.Windows.Forms.MessageBox]::Show("Robocopy cannot be found on this operating system, do you still want to proceed? You must make your own backups as this script did not make one for you", "Sage ERP X3: Ok To Proceed?", 4)
		if ($okToProceedStill -eq "No")
		{
			#Terminate execution of the script, DO NOT PROCEED ANY FURTHER
			Break
		}
	}	
	
	#Set Up Variables. If Variables are $null, terminate script
	
	#$sqlServerName = Read-Host "What is the name of your SQL Server (servername\instance)?"
	$mySqlServerInstanceName = Get-SQLInstance 
	$sqlServerName = [Microsoft.VisualBasic.Interaction]::InputBox("What is the name of your SQL Server (servername\instance)?", "Provide Full SQL Server Instance Name", $mySqlServerInstanceName )
	if (($sqlServerName -eq $null) -or ($sqlServerName -eq ""))
	{
		Write-Host "The SQL Server Instance name is not entered. Terminating execution of this script"
		Break
	}
	
	#$SystemDsnName = Read-Host "Provide System DSN name for the X3 Server. Usually something like X3V6"
	#if (($SystemDsnName  -eq $null) -or ($SystemDsnName -eq ""))
	#{
	#	Write-Host "The System DSN Name could not be found. Terminating execution of this script"
	#	Break
	#}
	
	#Hostname
	#$myHostName = Get-Content env:computername
	
	#Fully Qualified Domain Name - Note: Sometimes only the host name is returned, not the FQDN
	$myHostName = [System.Net.Dns]::GetHostByName(($Env::computerName)).HostName

	##### Stop services ##### 
	HandleX3Services $false

	### Adx_appli.xml ###
	Edit-XmlNodes $baseADXInstallPathInstDir"\Adx_appli.xml" -xpath "/install/module/component.application.servername" -value $myHostName

	### Adx-doc.xml ###
	Edit-XmlNodes $baseADXInstallPathInstDir"\Adx_doc.xml" -xpath "/install/module/component.doc.servername" -value $myHostName 

	### Adx-java.xml ###
	Edit-XmlNodes $baseADXInstallPathInstDir"\Adx_java.xml"-xpath "/install/module/component.serverjava.servername" -value $myHostName

	### Adx_runtime.xml ###
	Edit-XmlNodes $baseADXInstallPathInstDir"\Adx_runtime.xml" -xpath "/install/module/component.runtime.servername" -value $myHostName

	### Adx_sqlserveur.xml ###
	Edit-XmlNodes $baseADXInstallPathInstDir"\Adx_sqlserveur.xml" -xpath "/install/module/component.database.servername" -value $myHostName

	### Adx_srvimp.xml ###
	Edit-XmlNodes $baseADXInstallPathInstDir"\Adx_srvimp.xml" -xpath "/install/module/component.report.servername" -value $myHostName

	### Adx_web.xml ###
	Edit-XmlNodes $baseADXInstallPathInstDir"\Adx_web.xml" -xpath "/install/module/component.web.servername" -value $myHostName

	### adxinstalls.xml ###
	Edit-XmlNodes $baseADXInstallPathInstDir"\adxinstalls.xml" -xpath "/install/module/component.runtime.servername" -value $myHostName
	Edit-XmlNodes $baseADXInstallPathInstDir"\adxinstalls.xml" -xpath "/install/module/component.doc.servername" -value $myHostName
	Edit-XmlNodes $baseADXInstallPathInstDir"\adxinstalls.xml" -xpath "/install/module/component.report.servername" -value $myHostName
	Edit-XmlNodes $baseADXInstallPathInstDir"\adxinstalls.xml" -xpath "/install/module/component.database.servername" -value $myHostName
	Edit-XmlNodes $baseADXInstallPathInstDir"\adxinstalls.xml" -xpath "/install/module/application.http.url" -value $myHostName
	Edit-XmlNodes $baseADXInstallPathInstDir"\adxinstalls.xml" -xpath "/install/module/component.application.servername" -value $myHostName
	Edit-XmlNodes $baseADXInstallPathInstDir"\adxinstalls.xml" -xpath "/install/module/doc.files.accesspath" -value "\\$myHostName\X3V6DOC"
	Edit-XmlNodes $baseADXInstallPathInstDir"\adxinstalls.xml" -xpath "/install/module/doc.files.clientwebaccessurl" -value "http://$myHostName:80/AdxDoc_X3V6DOC"
	Edit-XmlNodes $baseADXInstallPathInstDir"\adxinstalls.xml" -xpath "/install/module/component.web.servername" -value $myHostName
	Edit-XmlNodes $baseADXInstallPathInstDir"\adxinstalls.xml" -xpath "/install/module/component.serverjava.servername" -value $myHostName

	### listsolutions.xml ###
	Edit-XmlNodes $baseADXInstallPathInstDir"\listsolutions.xml" -xpath "/solutions/solution/label" -value $myHostName
	Edit-XmlNodes $baseADXInstallPathInstDir"\listsolutions.xml" -xpath "/solutions/solution/servername" -value $myHostName

	### Folder's solution.xml ###
	Edit-XmlNodes "E:\SAGE\SAGEX3V6\X3V6PRM\Folders\solution.xml" -xpath "solution/module/application.http.url" -value $myHostName
	Edit-XmlNodes "E:\SAGE\SAGEX3V6\X3V6PRM\Folders\solution.xml" -xpath "solution/module/component.application.servername" -value $myHostName
	Edit-XmlNodes "E:\SAGE\SAGEX3V6\X3V6PRM\Folders\solution.xml" -xpath "solution/module/component.runtime.servername" -value $myHostName
	Edit-XmlNodes "E:\SAGE\SAGEX3V6\X3V6PRM\Folders\solution.xml" -xpath "solution/module/component.doc.servername" -value $myHostName
	Edit-XmlNodes "E:\SAGE\SAGEX3V6\X3V6PRM\Folders\solution.xml" -xpath "solution/module/doc.files.clientwebaccessurl" -value $myHostName":80"
	Edit-XmlNodes "E:\SAGE\SAGEX3V6\X3V6PRM\Folders\solution.xml" -xpath "solution/module/component.database.servername" -value $myHostName
	Edit-XmlNodes "E:\SAGE\SAGEX3V6\X3V6PRM\Folders\solution.xml" -xpath "solution/module/component.report.servername" -value $myHostName
	Edit-XmlNodes "E:\SAGE\SAGEX3V6\X3V6PRM\Folders\solution.xml" -xpath "solution/module/component.web.servername" -value $myHostName
	Edit-XmlNodes "E:\SAGE\SAGEX3V6\X3V6PRM\Folders\solution.xml" -xpath "solution/module/component.serverjava.servername" -value $myHostName
	Edit-XmlNodes "E:\SAGE\SAGEX3V6\X3V6PRM\Folders\solution.xml" -xpath "solution/module/doc.files.accesspath" -value $myHostName

	### User Profile Solutions.xml ###
	# This is needed for the console to be able to 
	# load the solution using the new server name
	$profileSolutionsFilePath = Get-Childitem env:APPDATA | %{ $_.Value }
	Edit-XmlNodes  "$profileSolutionsFilePath\sage\console\solutions.xml" -xpath "solutions/solution/servername" -value $myHostName	
	
	### User Profile adxaccounts.xml ###
	$profileAdxAccountsFilePath = Get-Childitem env:APPDATA | %{ $_.Value }
	Edit-XmlNodes "$profileSolutionsFilePath\sage\console\adxaccounts.xml" -xpath "accounts/adxd/server" -value $myHostName
	
	### User Profile documentations.xml ###
	$profileAdxAccountsFilePath = Get-Childitem env:APPDATA | %{ $_.Value }
	Edit-XmlNodes "$profileSolutionsFilePath\sage\console\documentations.xml " -xpath "documentations/documentation/servername" -value $myHostName
	
	### User Profile reports.xml ###
	$profileAdxAccountsFilePath = Get-Childitem env:APPDATA | %{ $_.Value }
	Edit-XmlNodes "$profileSolutionsFilePath\sage\console\reports.xml" -xpath "reportservers/reportserver/servername" -value $myHostName
	
	
	### User Profile serverjavas.xml ###
	$profileAdxAccountsFilePath = Get-Childitem env:APPDATA | %{ $_.Value }
	Edit-XmlNodes "$profileSolutionsFilePath\sage\console\serverjavas.xml" -xpath "javaservers/javaserver/servername" -value $myHostName
	
	
	### User Profile webs.xml ###
	$profileAdxAccountsFilePath = Get-Childitem env:APPDATA | %{ $_.Value }
	Edit-XmlNodes "$profileSolutionsFilePath\sage\console\webs.xml" -xpath "webservers/webserver/servername" -value $myHostName
	
	
	### Alter env.bat file ###
	#Set-Config 
	Set-Config  "E:\SAGE\SAGEX3V6\X3V6PRM\runtime\bin\env.bat" "DB_NAM" "x3vcdbdan1f\x3v6"

	### Set System DSN Name
	SetSystemDSNForDBConnection $sqlServerName
	
	### Start Services ###
	HandleX3Services $true
	
	##### Change SQL Server Name ######
	#Get relative path
	$ChangeSqlServerFile = split-path -parent $MyInvocation.MyCommand.Definition 
	$ChangeSqlServerFile += "\ChangeServerName.sql"
	sqlcmd -S $sqlServerName -E -i $ChangeSqlServerFile	
	
	Write-Host "System name change complete"
}
catch
{
	$_|select -ExpandProperty invocationinfo
	Write-Host "Error: $Error[0].  Terminating execution."
	$Error.Clear()
}
Finally{

	
	#Break

}
