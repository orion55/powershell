Clear-Host

$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent

$sourceDirectory = "d:\docum"
#$sourceDirectory = "$currentPath\source"

$destinationDirectory = "d:\2"
#$destinationDirectory = "$currentPath\destination"

$winrarDirectory = "c:\Program Files\WinRAR" 

$excludingDirectories = @('E', 'Foto', 'Hearthstone', 'ШП', 'ФУБ')

function isCheck{
	if (Test-Path $destinationDirectory){
		Remove-Item "$destinationDirectory\*.*" -Recurse
	} else {
		return $false
	}
	
	if (!(Test-Path $sourceDirectory)){
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
$catalogs = gci -ad -Path $sourceDirectory | Select-Object -Property Name | ? {$excludingDirectories -notcontains $_.Name} | % {$_.Name}

$i = 1
$max = $catalogs.Count

ForEach ($catalog in $catalogs){
	$rarProc = Start-Process "Rar.exe" "a -r -s -rr5p -ep1 -m3 -ms $destinationDirectory\$catalog.rar $sourceDirectory\$catalog" -Wait -Passthru 	
	if ($rarProc.ExitCode -eq 0) {  
		Write-Host -ForeGroundColor Blue "Успешаня архивация $catalog!"
	} else {
		Write-Host -ForeGroundColor Red "Ошибка архивации $catalog."
	}	
	Write-Progress -Activity $catalog -PercentComplete ($i / $max * 100) -Status "Archiving"
	$i++
}