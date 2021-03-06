#каталог сканирования
$info_in = "c:\UTA\INFO\OUT"
#email рассылки
$email = @("tmn_oit@tmn.apkbank.apk")
#$email = @("tmn_oit@tmn.apkbank.apk", "priem@tmn.apkbank.ru", "tmn-ksv@tmn.apkbank.ru")

Clear-Host
Set-Location $info_in

$info1 = Get-ChildItem $info_in -Name

foreach ($i1 in $info1){
	$cur_dir = "$info_in\$i1"
	$files = Get-ChildItem $cur_dir	
	
	if ($files -ne $null){
			$str1 = ""
			Write-Host -ForegroundColor Blue "Абонент $i1"						
			Get-ChildItem "*.*" -Path $cur_dir | ForEach-Object -Process { $str1 += $_.Fullname + "`n"; Write-Host -ForegroundColor Green $_.Fullname}	
			$str1 = -join("Проверьте UTA ", $env:COMPUTERNAME, "`n", $str1)			
			$encoding = [System.Text.Encoding]::UTF8
			Send-MailMessage -from "robot1@tmn.apkbank.ru" -to $email -Encoding $encoding -subject "Не отправлены сообщения абоненту $i1" -body $str1 -smtpServer 191.168.6.50 		
	}
}