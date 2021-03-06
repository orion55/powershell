#текущий файл
$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#каталог сканирования
$info_in = "c:\UTA\INFO\IN"
#$info_in = "$currentPath\IN"
#каталог архива
#$arch = "$currentPath\ARCHIV"
$arch = "c:\UTA\ARCHIV"
#каталог на флэшке
#$flash_in = "$currentPath\IN_MAIL"
$flash_in = "e:\IN_MAIL"

Clear-Host
Set-Location $info_in

$info1 = Get-ChildItem $info_in -Name

foreach ($i1 in $info1){
	$cur_dir = "$info_in\$i1"
	$files = Get-ChildItem $cur_dir	
	
	if ($files -ne $null){
		$date1 = Get-Date -uformat "%d.%m.%Y"
		$a_cur = "$arch\$i1\$date1"			
			
		if (!(Test-Path -Path $a_cur)){
			New-Item -path $a_cur -type directory > $null
		}
			
		$flash_in_mail =  "$flash_in\$i1"
		if (!(Test-Path -Path $flash_in_mail)){
			New-Item -path $flash_in_mail -type directory > $null
		}
			
		Write-Host -ForegroundColor Blue "Пришла почта от абонента $i1"
		
		$files11 = Get-ChildItem "*.*" -Path $cur_dir
		foreach ($f11 in $files11){
			if (Test-Path -Path "$a_cur\$f11"){
				Remove-Item "$a_cur\$f11" -Force					
			}
			
			Write-Host -ForegroundColor Green "Копируем на флэшку $flash_in_mail\$f11"
			Copy-Item "$cur_dir\$f11" -Destination $flash_in_mail
			Write-Host -ForegroundColor Green "Перемещаем в архив $a_cur\$f11"
			Move-Item "$cur_dir\$f11" -Destination $a_cur
		}
	}
}