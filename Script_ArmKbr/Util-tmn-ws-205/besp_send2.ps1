#программа копирования файлов из кворума на флешку БЭСП-платежей и копирование из в СМЭВ
#переменные
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#исходный путь
$orig_path = "m:\cb_out\BESP"
#$orig_path = "$dir1\cb_out\BESP"

#путь назначения
$dest_path = "d:\cli"
#$dest_path = "w:\exg\cli"
#$dest_path = "$dir1\cli"

#exp путь
$exp_path = "m:\cb_out\BESP\exp"
#$exp_path = "M:\CB_OUT\BeSP\exp"
#$exp_path = "$dir1\cb_out\BESP\exp"

#путь московского сервера
$mosk_path = "\\191.168.7.14\store\СМЭВ\TUMEN\IN"
$user1 = "tmn\tmn-svc_smev"
$pass1 = "ep6UN!vB0n"
$to = @("tmn_oit@tmn.apkbank.apk", "krainevaea@tmn.apkbank.ru")

#$orig_path = "d:\armkbr\exportbesp"
#$dest_path = "d:\armkbr\cli"
#$exp_path = "d:\armkbr\exp"
#$mosk_path = "\\191.168.7.14\store\СМЭВ\TUMEN"

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
	New-Item -ItemType directory $dest_path -Force | out-null
}

if (!(Test-Path -Path $exp_path)){
	Write-Error "Путь $exp_path не найден!"
	Write-Host "Нажмите любую клавишу для продолжения" 
	$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Exit
}

function fname($filename){
	$date1 = $filename.LastWriteTime
	$dt = "{0:yyyy}{0:MM}{0:dd}" -f $date1
	$ext1 = $file1.Extension
	$ext1 = $ext1.substring(1, 3)
	$file2 = -join ($dt, $ext1, "b.xml")
	return $file2
}

Set-Location $orig_path

#находим все файлы имя которых начинается на p
$files = Get-ChildItem "p*.*" -path $orig_path
if ($files -eq $null){
	Write-Warning "Файлы $orig_path\p*.* не найдены."
	Write-Output "Конец работы скрипта."
	Write-Host "Нажмите любую клавишу для продолжения" 
	$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Exit
} else {
	Write-Output "Подготовка к копированию файлов..."
}

#основные операции создания копии, переименования
Copy-Item "p*.*" -Destination $dest_path
Get-ChildItem "p*.*" | Rename-Item -NewName { $_.name -replace "p", "b" }
Copy-Item "b*.*" -Destination $exp_path

Set-Location $orig_path

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

$files = Get-ChildItem "b*.*" -path $orig_path
foreach ($file1 in $files){
	Write-Output $file1.fullname

	#копируем файлы на московский сервер 
	$file21 = fname($file1)		
	Copy-Item $file1 -Destination $file21
	
	#копируем файлы на сетевой диск T:
	$t = Get-PSDrive | ForEach-Object -process {$_.root} | Select-String "T:"
	if ($t -ne $null){
		Move-Item $file21 -Destination "t:\"
	}
}

#если ошибка копирования
$files1 = Get-ChildItem "*.xml" -path $orig_path
if ($files1 -ne $null){

Write-Host "Отправляем письмо..." -ForegroundColor Green

	$subject = "Файлы СМЭВ BESP не доставлены"
	$from = "krainevaea@tmn.apkbank.ru"
	$smtpHost = "191.168.6.50"	
	
	$email = New-Object System.Net.Mail.MailMessage 
	foreach($mailTo in $to){
	    $email.To.Add($mailTo)
	}
	 
	$email.From = $from
	$email.Subject = $subject
	$email.Body = ""
	 
	$client = New-Object System.Net.Mail.SmtpClient $smtpHost
	#использовать текущий логин\пароль для авторизации на почтовом сервере
	$client.UseDefaultCredentials = $true
	$client.Send($email)
	
	Write-Host "Письмо отправленно..." -ForegroundColor Green
	
	#$encoding = [System.Text.Encoding]::UTF8
	#$str1 = ""
	#Get-ChildItem "*.xml" -Path $orig_path | ForEach-Object -Process { $str1 += $_.Fullname + "`n"}
	#Send-MailMessage -from "robot@tmn.apkbank.ru" -to "tmn_oit@tmn.apkbank.apk" -Encoding $encoding -subject "Файлы СМЭВ BESP не доставлены" -body $str1 -smtpServer 192.168.72.15	
}
		
#удаляем сетевой диск T:
$t = Get-PSDrive | ForEach-Object -process {$_.root} | Select-String "T:"
if ($t -ne $null){
	Write-Output "Отключаем сетевой диск"
	net use t: /delete /yes
}

Remove-Item "$orig_path\b*.*"

Write-Output "Конец работы скрипта."