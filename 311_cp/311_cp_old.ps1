$global:dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
$orig_dir = "\\191.168.7.14\RBS\TMN\311p"
$dest_dir = "\\tmn-ts-01\311p\Arhive"
$work_dir = "\\tmn-rkc-01\WORK"
$global:post_fix = @("RBS", "WAY4")

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


function Copy_log{
	Param($o_dir, $d_dir)
	Write-Host -ForegroundColor Green "Копируем файлы из $o_dir в $d_dir"
	
	foreach ($o1 in $o_dir){			
		$t_list = Get-ChildItem "*.xml" -Name -Path $o_dir
		if ($t_list -ne $null){
			$n = 0
			foreach ($t1 in $t_list){				
				Copy-Item -Path "$o_dir\$t1" -Destination $d_dir
				$dt1 = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
				$dt1 + "`t" + "Copy $o_dir\$t1 --> $d_dir" | Out-File -Append -FilePath $logfilename -Encoding UTF8
				Write-Host -ForegroundColor Yellow "$o_dir\$t1 --> $d_dir"
				$n++
			}			
			Write-Host -ForegroundColor Yellow "Скопировано $n файлов"
			$dt1 + "`t" + "Скопировано $n файлов" | Out-File -Append -FilePath $logfilename -Encoding UTF8
		}
	}	
}

function Delete_log{
	Param($o_dir, $d_dir)

	Write-Host -ForegroundColor Green "Удаляем файлы из $o_dir"
				
	$t_list = Get-ChildItem "*.xml" -Name -Path $o_dir
	if ($t_list -ne $null){			
		$n = 0
		foreach ($t1 in $t_list){
			$dt1 = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
			if (Test-Path("$o_dir\$t1")){
				Remove-Item -Path "$o_dir\$t1"						
				$dt1 + "`t" + "Delete $o_dir\$t1" | Out-File -Append -FilePath $logfilename -Encoding UTF8
				Write-Host -ForegroundColor Red "Delete $o_dir\$t1"
				$n++
			} else {
				$dt1 + "`t" + "Error copy $o_dir\$t1" | Out-File -Append -FilePath $logfilename -Encoding UTF8
				Write-Host -ForegroundColor Red "Error $o_dir\$t1"					
			}
		}
		Write-Host -ForegroundColor Red "Удалено $n файлов"
		$dt1 + "`t" + "Удалено $n файлов" | Out-File -Append -FilePath $logfilename -Encoding UTF8
	}
}

Test_d($orig_dir)

$dt1 = Get-Date -Format "ddMMyyyy"
$arch_dir = -join ($dest_dir, '\', $dt1)
if (!(Test-Path -Path $arch_dir )){
	New-Item -ItemType directory $arch_dir -Force | out-null	
}

foreach ($p1 in $post_fix){
	$p11 = -join($arch_dir, "\", $p1)		
	if (!(Test-Path -Path $p11)){
		New-Item -ItemType directory $p11 -Force | out-null	
	}	
}

$o_dir1 = -join($orig_dir, '\WAY4')
$d_dir1 = -join ($arch_dir, '\WAY4')
Copy_log -o_dir $o_dir1 -d_dir $d_dir1

Copy-Item -Path "$o_dir1\*.log" -Destination $d_dir1
$dt1 = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
$dt1 + "`t" + "Copy $o_dir\*.log --> $d_dir1" | Out-File -Append -FilePath $logfilename -Encoding UTF8

$o_dir1 = -join ($arch_dir, '\WAY4')
Copy_log -o_dir $o_dir1 -d_dir $work_dir

$o_dir1 = -join($orig_dir, '\WAY4')
$d_dir1 = -join ($arch_dir, '\WAY4')
Delete_log -o_dir $o_dir1 -d_dir $d_dir1

Remove-Item -Path "$o_dir1\*.log"
$dt1 = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
$dt1 + "`t" + "Delete $o_dir1\*.log" | Out-File -Append -FilePath $logfilename -Encoding UTF8

$o_dir2 = -join($orig_dir, '\RBS')
$dirs2 = Get-ChildItem "BN*" -Name -Path $o_dir2
foreach ($dr in $dirs2){
	$o_dir1 = -join($o_dir2, '\', $dr)
	$d_dir1 = -join ($arch_dir, '\RBS')
	Copy_log -o_dir $o_dir1 -d_dir $d_dir1
	
	$o_dir1 = -join ($arch_dir, '\RBS')	
	Copy_log -o_dir $o_dir1 -d_dir $work_dir
	
	$o_dir1 = -join($o_dir2, '\', $dr)
	$d_dir1 = -join ($arch_dir, '\RBS')
	Delete_log -o_dir $o_dir1 -d_dir $d_dir1
}

foreach ($dr in $dirs2){
	$o_dir1 = -join($o_dir2, '\', $dr)
	Write-Host -ForegroundColor Magenta "Удаляем каталог $o_dir1"
	Remove-Item -Path $o_dir1 -Force -Recurse
	
	$dt1 = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
	$dt1 + "`t" + "Delete directory $o_dir1" | Out-File -Append -FilePath $logfilename -Encoding UTF8	
}