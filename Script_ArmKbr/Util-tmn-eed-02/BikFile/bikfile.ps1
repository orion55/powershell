#Программа синхронизации антивирусных баз
#текущий файл
$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#исходный каталог
$sourceDirectory = "e:\Bik"
#каталог архива
#$destinationDirectory = "$currentPath\Bik"
$destinationDirectory = "c:\Bik"

function isCheck{
	if (!(Test-Path $sourceDirectory)){
		return $false
	}
	
	if (!(Test-Path $destinationDirectory)){
		New-Item -ItemType directory $destinationDirectory -Force | out-null
		return $true
	}	
	return $true	
}

if (!(isCheck)){
	exit
}

Clear-Host
Set-Location $currentPath

Write-Host -ForegroundColor Green "Начинаем синхронизаци..."

$AllArgs = @($sourceDirectory, $destinationDirectory, "/LOG+:$currentPath\robocopy.log", '/MIR', '/ZB', '/R:30', '/W:10', '/TBD', '/TEE', '/ETA')
&"robocopy.exe" $AllArgs

Write-Host -ForegroundColor Green "Завершение синхронизации"