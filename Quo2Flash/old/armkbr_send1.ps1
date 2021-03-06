#переменные
#исходный путь
$orig_path = "m:\cb_out"
#"u:\users\kraineva\out\exp"
#путь назначения
$dest_path = "\\tmn-eed-01\uarm2\exg\cli"
#путь московсого сервера
$mosk_path = "\\191.168.7.14\store\СМЭВ\TUMEN\IN"
$user1 = "tmn\tmn-svc_smev"
$pass1 = "ep6UN!vB0n"

#$mosk_path = "\\191.168.7.14\store\СМЭВ\TUMEN"
#$orig_path = "d:\armkbr\orig"
#$dest_path = "d:\armkbr\dest"


Clear-Host

Write-Output "Запуск скрипта..."

#проверка существования путей
if (!(Test-Path -Path $orig_path)){
	Write-Error "Путь $orig_path не найден!"
	Write-Host "Нажмите любую клавишу для продолжения" 
	$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Exit
}

if (!(Test-Path -Path $dest_path)){
	Write-Error "Путь $dest_path не найден!"
	Write-Host "Нажмите любую клавишу для продолжения" 
	$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Exit
}

function fname($filename){
	$date1 = $filename.LastWriteTime
	$dt = "{0:yyyy}{0:MM}{0:dd}" -f $date1
	$ext1 = $file1.Extension
	$ext1 = $ext1.substring(1, 3)
	$file2 = -join ($dt, $ext1, ".xml")	
	return $file2
}

Set-Location $orig_path

#находим все файлы имя которых начинается на i
$files = Get-ChildItem "i*.*" -path $orig_path
if ($files -eq $null){
	Write-Warning "Файлы $orig_path\i*.* не найдены."
	Write-Output "Конец работы скрипта."
	Write-Host "Нажмите любую клавишу для продолжения" 
	$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Exit
} else {
	Write-Output "Подготовка к копированию файлов..."
}

#проверяем доступность московсого сервера и подключаем сетевой диск T:
$ip_mosk = [regex]::Match($mosk_path,"(?<=\\\\).*?(?=\\)")
Write-Output "Проверяем доступность московского сервера"
if (test-connection -computer $ip_mosk.value){	
	$t = Get-PSDrive | ForEach-Object -process {$_.root} | Select-String "T:"	
	if ($t -ne $null){
		net use t: /delete /yes								
	}
	Write-Output "Подключаем сетевой диск"
	net use t: $mosk_path /user:$user1 $pass1
} else {
	Write-Error "Ip-адрес $ip_mosk.value не доступен!"
}

foreach ($file1 in $files){
	Write-Output $file1.fullname

	#копируем файлы на сервер АРК КБР
	Copy-Item $file1 -Destination $dest_path -force

	#копируем файлы на московский сервер 
	$file21 = fname($file1)		
	Copy-Item $file1 -Destination $file21 -force
	
	#копируем файлы на сетевой диск T:
	$t = Get-PSDrive | ForEach-Object -process {$_.root} | Select-String "T:"
	if ($t -ne $null){
		Move-Item $file21 -Destination "t:\" -force
#		if (!(Test-Path -Path "T:\$file2" -PathType Leaf)){
#			Move-Item $file21 -Destination "T:\"
#		} else {
#			Remove-Item $file21
#		}	
	}
	#перемещаем файлы в архив
	$file21 = $file1.Name -replace "i", "a"	
	Rename-Item $file1 -NewName $file21 -force
}

#если ошибка копирования
$files1 = Get-ChildItem "*.xml" -path $orig_path
if ($files1 -ne $null){
	$encoding = [System.Text.Encoding]::UTF8
	$str1 = ""
	Get-ChildItem "*.xml" -Path $orig_path | ForEach-Object -Process { $str1 += $_.Fullname + "`n"}
	Send-MailMessage -from "robot@tmn.apkbank.ru" -to "tmn_oit@tmn.apkbank.apk" -Encoding $encoding -subject "Файлы СМЭВ не доставлены" -body $str1 -smtpServer 192.168.72.15	
}
		
#удаляем сетевой диск T:
$t = Get-PSDrive | ForEach-Object -process {$_.root} | Select-String "T:"
if ($t -ne $null){
	Write-Output "Отключаем сетевой диск"
	net use t: /delete /yes
}

Write-Output "Конец работы скрипта."