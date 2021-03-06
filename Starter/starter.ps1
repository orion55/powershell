#Программа запуска программ один раз в день
#текущий путь
$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#путь до скрипта файла обновления Касперского
$kasperFile = "d:\Ps1\kasper\KasperUpdates.ps1"
#путь до скрипта файла обновления БИК
$bikFile = "d:\Ps1\BikFile\bikfile.ps1"
#путь до скрипта файла отправки в АРМ КБР
$armkbrFile = "d:\Ps1\Quo2Flash\armkbr_send2.ps1"

Clear-Host
Set-Location $currentPath

$nowDate = Get-Date -f 'ddMMyyyy'
$fileName = "check_$nowDate.txt"
$fullFileName = "$currentPath\$fileName"


if (!(Test-Path $fullFileName)){
	Remove-Item "check_*.txt"
	New-Item -Path $fullFileName -ItemType "file" | Out-Null
	
	if (Test-Path $kasperFile){
		Start-Process powershell.exe -ArgumentList "-file $kasperFile"
	}
	if (Test-Path $bikFile){
		Start-Process powershell.exe -ArgumentList "-file $bikFile"
	}
}

if (Test-Path $armkbrFile){
	Start-Process powershell.exe -ArgumentList "-file $armkbrFile"
}