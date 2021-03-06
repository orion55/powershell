#Программа копирования списка БИКов
#текущий файл
$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#файл с БИКами
$bikFile = "BNKSEEK.DBF"
#исходный каталог
$sourceFile = "\\3170-file\quo_l\BIKViewer\Update\$bikFile"
#каталог архива
#$destinationDirectory = "$currentPath\Bik"
$destinationDirectory = "d:\Bik"

function isCheck{
	if (!(Test-Path $sourceFile)){
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

$bikDestinationFile = "$destinationDirectory\$bikFile"

$flagBik = $false

if (!(Test-Path $bikDestinationFile)){
	$flagBik = $true
} else {
	$dateSourceFile = [datetime](Get-ItemProperty -Path $sourceFile -Name LastWriteTime).lastwritetime
	$dateDestinationFile = [datetime](Get-ItemProperty -Path $bikDestinationFile -Name LastWriteTime).lastwritetime
	if ($dateSourceFile -ne $dateDestinationFile){
		$flagBik = $true
	}
}

if ($flagBik){
	Write-Host -ForegroundColor Green "Копируем БИК-файл $sourceFile"
	Copy-Item $sourceFile -Destination $destinationDirectory -Force
}