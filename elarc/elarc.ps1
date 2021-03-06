#Программа архивации файлов электронного архива
#текущий файл
$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#исходный каталог
$sourceDirectory = "U:\USERS\kraineva\OUT"
#каталог архива
$destinationDirectory = "U:\SENDDOC\ELARC"
#каталог winrar
$winrarDirectory = "C:\Program Files\WinRar"
#файлы для архивации
$includingFiles = @('iElArc_d.out', 'income_elarch.out')

Clear-Host

function isCheck{	
	if (!(Test-Path $sourceDirectory)){
		Write-Host -ForeGroundColor Red "Каталог $sourceDirectory не найден!"
		return $false
	}
	
	foreach($out in $includingFiles){
		if (!(Test-Path $sourceDirectory\$out)){
			Write-Host -ForeGroundColor Red "Файл $sourceDirectory\$out не найден!"
			return $false
		}		
	}
	
	if (!(Test-Path $destinationDirectory)){
		Write-Host -ForeGroundColor Red "Каталог $destinationDirectory не найден!"
		return $false
	}
	
	
	if (!(Test-Path "$winrarDirectory\rar.exe")){
		Write-Host -ForeGroundColor Red "Файл $winrarDirectory\rar.exe не найден!"
		return $false
	}
	return $true	
}

if (!(isCheck)){
	exit
}

Set-Location $winrarDirectory

$contentIncome = Get-Content "$sourceDirectory\income_elarch.out"
$regDate = "[0-9]{2}/[0-9]{2}/[0-9]{4}"
if ($contentIncome[5] -match $regDate){
	$dateFile = $Matches.Values
} else {
	Write-Host -ForeGroundColor Red "Неверный формат файл income_elarch.out!"
	exit
}
$arrayDate = $dateFile -split("/")
[array]::Reverse($arrayDate)
$dateReport = $arrayDate -join ""
$filenameArchive = "$destinationDirectory\" + $dateReport + '_TMN.rar'

if (Test-Path $filenameArchive){
	Remove-Item $filenameArchive -Force		
}
$files = ''
foreach($out in $includingFiles){
	$files += ($sourceDirectory + "\" + $out + " ")
}

$rarProc = Start-Process "Rar.exe" "a -s -rr5p -ep1 -m3 $filenameArchive $files" -Wait -Passthru 	
if ($rarProc.ExitCode -eq 0) {  
	Write-Host -ForeGroundColor Blue "Успешная архивация $filenameArchive!"
} else {
	Write-Host -ForeGroundColor Red "Ошибка архивации $filenameArchive."
}