# Author: 			Bob Delamater
# Date:				12/17/2014
# Description:		Compile all source files within the trt directory that meet a filter criteria

$ErrorActionPreference = "Stop"
$Error.Clear()
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")


try{
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$envPath = [Microsoft.VisualBasic.Interaction]::InputBox("What is the path to the env.bat file?", "Path to Env.bat", "C:\SAGE\SAGEX3V6\X3V6\runtime\bin")
$batchFileOutput = [Microsoft.VisualBasic.Interaction]::InputBox("Where would you like to store the batch file?", "Path to batch file", "C:\Sage\CompileSource.bat")
$trtDir = "C:\SAGE\SAGEX3V6\X3V6\Folders\DEMO\TRT"
$myFilter = "ZSTKALL.src"

Set-Content -Value "$envPath\env.bat" -Path $batchFileOutput

Get-ChildItem -Path $trtDir -Filter $myFilter |
ForEach-Object{
	$fileName = $_.name
	$cmd = "$envPath\valtrt.exe -l ENG DEMO $fileName "
	Add-Content -Value $cmd -Path $batchFileOutput
}

#$cmd = "$envPath\valtrt.exe -l ENG DEMO ZSTKALL"

#$mystr = "123 "
#Get-ChildItem -Path "C:\SAGE\SAGEX3V6\X3V6\Folders\DEMO\TRT" | select name


}
catch
{
	$_|select -ExpandProperty invocationinfo
	Write-Host "Error: $Error[0].  Terminating execution."
	$Error.Clear()
}
