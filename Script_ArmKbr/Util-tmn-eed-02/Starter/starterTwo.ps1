#Программа запуска программ один раз в день
#текущий путь
$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#путь до скрипта файла почты Uta
#$utaFile = "d:\Ps1\UtaMail\UtaIn2Flash.ps1"
$utaFile = "C:\Util\UtaMail\UtaIn2Flash.ps1"
#путь до скрипта файла отправки в АРМ КБР
$armkbrFile = "C:\Util\Razbor\razbor_EPD_ESID.exe"

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
	set-location "C:\Util\Razbor"
	Start-Process $armkbrFile
}