#каталог сканирования
#$info_in = "c:\UTA\INFO\IN"
$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#$info_in = "c:\UTA\INFO\IN"
$info_in = $currentPath + "\IN"
#каталог архива
#$arch = "c:\UTA\ARCHIV"
$arch = $currentPath + "\ARCHIV"
#папка пользователя для сообщений в отчетности
$sdko = "71svcsdko"
#email рассылки
$email = @("tmn-goe@tmn.apkbank.apk")
#$email = @("letter-cb@tmn.apkbank.apk")

Clear-Host
Set-Location $info_in

$info1 = Get-ChildItem $info_in -Name

foreach ($i1 in $info1){
	$cur_dir = "$info_in\$i1"
	$files = Get-ChildItem $cur_dir	
	
	if ($files -ne $null){
		if ($i1 -ne $sdko){
			$date1 = Get-Date -uformat "%d.%m.%Y"
			$a_cur = "$arch\$i1\$date1"			
			
			if (!(Test-Path -Path $a_cur)){
				New-Item -path $a_cur -type directory > $null
			}
			
			Write-Host -ForegroundColor Blue "Абонент $i1"			
			[System.Collections.ArrayList]$str1 = @()
			Get-ChildItem "*.*" -Path $cur_dir | ForEach-Object -Process { $str1.add($_.Fullname) > $null; Write-Host -ForegroundColor Green $_.Fullname}			
			$encoding = [System.Text.Encoding]::UTF8
			$str2 = -join ("Получено через UTA ", $env:COMPUTERNAME)
			Send-MailMessage -from "robot1@tmn.apkbank.ru" -to $email -Encoding $encoding -subject "Пришли сообщения из ГУ ЦБ - абонент $i1" -body $str2 -smtpServer 191.168.6.50 -Attachments $str1
			
			$files11 = Get-ChildItem "*.*" -Path $cur_dir
			foreach ($f11 in $files11){				
				if (Test-Path -Path "$a_cur\$f11"){
					Remove-Item "$a_cur\$f11" -Force					
				}
				Write-Host -ForegroundColor Green "Перемещаем в архив $a_cur\$f11"
				Move-Item "$cur_dir\$f11" -Destination $a_cur
			}			
		} else {
			$encoding = [System.Text.Encoding]::UTF8
			Send-MailMessage -from "robot1@tmn.apkbank.ru" -to "tmn_oit@tmn.apkbank.apk" -Encoding $encoding -subject "Необработанные сообщения от абонента $i1" -body "Проверьте ПТК ПСД! Сообщения в папке $cur_dir" -smtpServer 191.168.6.50
			Write-Host -ForegroundColor Blue "Абонент $i1"
			Write-Host -ForegroundColor Green "Есть необработанные сообщения. Проверьте ПТК ПСД! Сообщения в папке $cur_dir"			
		}
	}
}