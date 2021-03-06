#Программа запуска программ один раз в день
#текущий путь
$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#путь до скрипта файла почты Uta
$utaFile = "C:\Util\UtaMail\Flash2UtaIn.ps1"
#путь до скрипта файла отправки в АРМ КБР
$armkbrFile = "C:\Util\Flash2Quo.ps1"

Clear-Host
Set-Location $currentPath

$nowDate = Get-Date -f 'ddMMyyyy'
$fileName = "control_$nowDate.txt"
$fullFileName = "$currentPath\$fileName"


if (!(Test-Path $fullFileName)){
	Remove-Item "control_*.txt"
	New-Item -Path $fullFileName -ItemType "file" | Out-Null
	
	if (Test-Path $utaFile){
		Start-Process powershell.exe -ArgumentList "-file $utaFile"
	}
}

if (Test-Path $armkbrFile){
	Start-Process powershell.exe -ArgumentList "-file $armkbrFile"
}