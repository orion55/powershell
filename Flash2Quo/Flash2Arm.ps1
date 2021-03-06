#программа копирования файлов АРМ КБР с флешки в кворум
$global:dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

$orig_dir = "$dir1\Flash"
#$orig_dir = "d:"
$dest_dir = "$dir1\Server"
#$dest_dir = "c:\uarm3\exg"
$global:post_fix = @("cli")

Clear-Host
Set-Location $dest_dir

$dt = Get-Date -Format "dd-MM-yyyy"
New-Item -ItemType directory "$dir1\log" -Force | out-null #Создаю директорию для логов
$global:logfilename = "$dir1\log\" + $dt + "_LOG.log"

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
			$numError = 0
			$flag = $true
			Do {
				try {
					[System.Windows.Forms.Application]::DoEvents()
					Copy-Item -Path "$p11\$t1" -Destination $d11 -ErrorAction Stop					
					$orig_hash = (Get-FileHash -Algorithm SHA256 "$p11\$t1").Hash
					$dest_hash = (Get-FileHash -Algorithm SHA256 "$d11\$t1").Hash					
					if ($orig_hash -ne $dest_hash){
						$flag = $true
						$ErrorMessage = "Ошибка: Хеш-суммы файлов $p11\$t1 и $d11\$t1 не совпадают!"						
						$dt1 + "`t" + $ErrorMessage | Out-File -Append -FilePath $logfilename -Encoding UTF8
						Write-Host -ForegroundColor Red "$ErrorMessage"
						if ($numError -lt 9){
							$numError++
							Start-Sleep -Seconds 5
						} else {
							$flag = $false
							Remove-Item -Path "$d11\$t1"
						}
					} else {
						$flag = $false
						$dt1 = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
						$dt1 + "`t" + "Копирование $p11\$t1 --> $d11" | Out-File -Append -FilePath $logfilename -Encoding UTF8
						Write-Host -ForegroundColor Blue "$p11\$t1 --> $d11"				
						$n++
					}
				}
				catch{					
					$ErrorMessage = $_.Exception.Message
					$dt1 + "`t" + "Ошибка: $ErrorMessage" | Out-File -Append -FilePath $logfilename -Encoding UTF8
					Write-Host -ForegroundColor Red "$ErrorMessage"					
				}
			}
			While ($flag)
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
				$flag = $true
				$numError = 0
				Do {
					try {
						[System.Windows.Forms.Application]::DoEvents() 
						Remove-Item -Path "$p11\$t1" -ErrorAction Stop
						$dt1 + "`t" + "Удаление $p11\$t1" | Out-File -Append -FilePath $logfilename -Encoding UTF8
						Write-Host -ForegroundColor Blue "Delete $p11\$t1"
						$n++
						$flag = $false
					}
					catch{					
						$ErrorMessage = $_.Exception.Message
						$dt1 + "`t" + "Ошибка: $ErrorMessage" | Out-File -Append -FilePath $logfilename -Encoding UTF8
						Write-Host -ForegroundColor Red "$ErrorMessage"
						if ($numError -lt 9){
							$numError++
							Start-Sleep -Seconds 5
						} else {
							$flag = $false
						}						
					}
				}
				While ($flag)
			}
		}
		Write-Host -ForegroundColor Blue "Удалено $n файлов"
		$dt1 + "`t" + "Удалено $n файлов" | Out-File -Append -FilePath $logfilename -Encoding UTF8
	}	
}