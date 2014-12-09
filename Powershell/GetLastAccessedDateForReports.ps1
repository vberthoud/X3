# In order for last accessed date to be accurate you must set the following registry key 
# HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem
# Set the NtfsDisableLastAccessUpdate = Hexadecimal value of 0

Get-ChildItem -Path "C:\ProgramData\Sage\Safe X3 Client\V1\Data\X3_x3v6stdp26pd_1806\ENG\Report" | select name, *time | Export-Csv -Path "C:\Temp\LastAccessedDateOfSageReports.csv" -Encoding ascii -NoTypeInformation
$HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
$HOST.UI.RawUI.Flushinputbuffer()
