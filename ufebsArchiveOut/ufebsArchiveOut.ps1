#Программа перемещения в архив файлов, которые уже отработаны автоматом УФЭБС
#текущий файл
$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#исходный каталог
$sourceDirectory = "$currentPath\CB_OUT"
#каталог архива
$destinationDirectory = "$sourceDirectory\ARCHIVE"

Clear-Host

function isCheck{
	if (!(Test-Path $sourceDirectory)){
		return $false
	}
	
	if (!(Test-Path $destinationDirectory)){
		return $false
	}	
	
	return $true	
}

if (!(isCheck)){
	exit
}

$findFiles = Get-ChildItem "a*.*" -Path $sourceDirectory | where { ! $_.PSIsContainer }
$count = ($findFiles|Measure-Object).count

if ($count -eq 0){
	exit
}

$nowDate = Get-Date -f 'dd.MM.yyyy'
$dateDirectory = $destinationDirectory + '\' + $nowDate

if (!(Test-Path $dateDirectory)){
	New-Item -ItemType directory $dateDirectory -Force | out-null
}

Set-Location $sourceDirectory
Move-Item $findFiles -Destination $dateDirectory -Force