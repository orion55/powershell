#программа копирования файлов АРМ КБР с флешки в кворум
$global:dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

$orig_dir = "$dir1\CB_OUT"
#$orig_dir = "d:"
$dest_dir = "$dir1\MFROUT"
#$dest_dir = "M:"
#$global:post_fix = @("CB_IN")

Clear-Host
Set-Location $dest_dir

$dt = Get-Date -Format "dd-MM-yyyy"
New-Item -ItemType directory "$dir1\log" -Force | out-null #Создаю директорию для логов
$global:logfilename="$dir1\log\"+$dt+"_LOG.log"

function Test_d($dirs1){	
	#проверка существования путей
	if (!(Test-Path -Path $dirs1)){
		Write-Host "Путь $dirs1 не найден!" -ForegroundColor Red
		Write-Host "Нажмите любую клавишу для продолжения" 
		Read-Host "Нажмите Enter"			
		Exit
	}
}

Test_d($orig_dir)
Test_d($dest_dir)

Write-Host -ForegroundColor Cyan "Копируем файлы"

$t_list = Get-ChildItem "710*.962" -Name -Path $orig_dir
if ($t_list -ne $null){
	Write-Host -ForegroundColor Green "`n$orig_dir"
	$n = 0
	foreach ($t1 in $t_list){				
		Copy-Item -Path "$orig_dir\$t1" -Destination $dest_dir
		$dt1 = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
		$dt1 + "`t" + "Copy $orig_dir\$t1 --> $dest_dir" | Out-File -Append -FilePath $logfilename -Encoding UTF8
		Write-Host -ForegroundColor Blue "$orig_dir\$t1 --> $dest_dir"
		$n++
	}			
	Write-Host -ForegroundColor Blue "Скопировано $n файлов"
	$dt1 + "`t" + "Скопировано $n файлов" | Out-File -Append -FilePath $logfilename -Encoding UTF8
}

Write-Host -ForegroundColor Cyan "`nУдаляем файлы"
$t_list = Get-ChildItem "710*.962" -Name -Path $orig_dir
if ($t_list -ne $null){
	Write-Host -ForegroundColor Green "`n$dest_dir"
	$n = 0
	foreach ($t1 in $t_list){
		$dt1 = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
		if (Test-Path("$dest_dir\$t1")){
			Remove-Item -Path "$orig_dir\$t1"						
			$dt1 + "`t" + "Delete $orig_dir\$t1" | Out-File -Append -FilePath $logfilename -Encoding UTF8
			Write-Host -ForegroundColor Blue "Delete $orig_dir\$t1"
			$n++
		} else {
			$dt1 + "`t" + "Error copy $orig_dir\$t1" | Out-File -Append -FilePath $logfilename -Encoding UTF8
			Write-Host -ForegroundColor Red "Error $orig_dir\$t1"
		}
	}
	Write-Host -ForegroundColor Blue "Удалено $n файлов"
	$dt1 + "`t" + "Удалено $n файлов" | Out-File -Append -FilePath $logfilename -Encoding UTF8
}	