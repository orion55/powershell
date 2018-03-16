#программа копирования файлов АРМ КБР с флешки в кворум
$global:dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#$orig_dir = "$dir1\Flash"
$orig_dir = "d:"
#$dest_dir = "$dir1\Server"
$dest_dir = "M:"
$global:post_fix = @("CB_IN")

Clear-Host
Set-Location $dest_dir

$dt = Get-Date -Format "dd-MM-yyyy"
New-Item -ItemType directory "$dir1\log" -Force | out-null #Создаю директорию для логов
$global:logfilename="$dir1\log\"+$dt+"_LOG.log"

function Test_d($dirs1){	
	foreach ($p1 in $post_fix){
		#проверка существования путей
		$p11 = -join($dirs1, "\", $p1)		
		if (!(Test-Path -Path $p11)){
			Write-Host "Путь $p11 не найден!" -ForegroundColor Red
			Write-Host "Нажмите любую клавишу для продолжения" 
			Read-Host "Нажмите Enter"			
			Exit
		}
	}
}

Test_d($orig_dir)
Test_d($dest_dir)

Write-Host -ForegroundColor Cyan "Копируем файлы"

foreach ($p1 in $post_fix){
	$p11 = -join($orig_dir, "\", $p1)
	$d11 = -join($dest_dir, "\", $p1)
	$t_list = Get-ChildItem "*.*" -Name -Path $p11
	if ($t_list -ne $null){
		Write-Host -ForegroundColor Green "`n$p11"
		$n = 0
		foreach ($t1 in $t_list){				
			Copy-Item -Path "$p11\$t1" -Destination $d11
			$dt1 = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
			$dt1 + "`t" + "Copy $p11\$t1 --> $d11" | Out-File -Append -FilePath $logfilename -Encoding UTF8
			Write-Host -ForegroundColor Blue "$p11\$t1 --> $d11"
			$n++
		}			
		Write-Host -ForegroundColor Blue "Скопировано $n файлов"
		$dt1 + "`t" + "Скопировано $n файлов" | Out-File -Append -FilePath $logfilename -Encoding UTF8
	}
}

Write-Host -ForegroundColor Cyan "`nУдаляем файлы"
foreach ($p1 in $post_fix){
	$p11 = -join($orig_dir, "\", $p1)
	$d11 = -join($dest_dir, "\", $p1)
		
	$t_list = Get-ChildItem "*.*" -Name -Path $p11
	if ($t_list -ne $null){
		Write-Host -ForegroundColor Green "`n$p11"
		$n = 0
		foreach ($t1 in $t_list){
			$dt1 = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
			if (Test-Path("$d11\$t1")){
				Remove-Item -Path "$p11\$t1"						
				$dt1 + "`t" + "Delete $p11\$t1" | Out-File -Append -FilePath $logfilename -Encoding UTF8
				Write-Host -ForegroundColor Blue "Delete $p11\$t1"
				$n++
			} else {
				$dt1 + "`t" + "Error copy $p11\$t1" | Out-File -Append -FilePath $logfilename -Encoding UTF8
				Write-Host -ForegroundColor Red "Error $p11\$t1"					
			}
		}
		Write-Host -ForegroundColor Blue "Удалено $n файлов"
		$dt1 + "`t" + "Удалено $n файлов" | Out-File -Append -FilePath $logfilename -Encoding UTF8
	}	
}