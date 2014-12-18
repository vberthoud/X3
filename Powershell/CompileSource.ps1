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
$trtDir = [Microsoft.VisualBasic.Interaction]::InputBox("Where is the TRT directory?", "Path to TRT direcotry file", "C:\SAGE\SAGEX3V6\X3V6\Folders\DEMO\TRT") 
$myFilter = [Microsoft.VisualBasic.Interaction]::InputBox("File filter", "Set File Filter", "Z*.src") 

Set-Content -Value "CALL $envPath\env.bat" -Path $batchFileOutput

Get-ChildItem -Path $trtDir -Filter $myFilter |
ForEach-Object{
	$fileName = $_.BaseName
	$cmd = "$envPath\valtrt.exe -l ENG DEMO $fileName "
	Add-Content -Value $cmd -Path $batchFileOutput
}

Add-Content -Value "Pause" -Path $batchFileOutput

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
