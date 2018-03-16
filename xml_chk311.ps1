#Проверка отчетов из ЦБ на наличие сообщений об ошибках

$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#$out = "$dir1\out"
$out = "l:\PTK PSD\Post\ELO\OUT"
$email = @("tmn-lov@tmn.apkbank.apk", "tmn-goe@tmn.apkbank.ru", "pastuhova@tmn.apkbank.ru")
#$email = @("tmn-goe@tmn.apkbank.ru")

Clear-Host
Set-Location $dir1

$xml1 = Get-ChildItem "$out\UV*.xml"
$count = ($xml1|Measure-Object).count

if ($count -eq 0){
	exit
}

foreach ($x in $xml1){
	[xml]$content = Get-Content $x
	$rez_arh = $content.UV.REZ_ARH	
	
	if ($rez_arh -notlike "принят"){
		$text1 = "Ошибка! Отчет $x сообщает об ошибке: `"$rez_arh`""
		Write-Host -ForegroundColor Red $text1
		
		Write-Host "Отправляем письмо" -ForegroundColor Green
		$date1 = Get-Date	
		$encoding = [System.Text.Encoding]::UTF8
		Send-MailMessage -To $email -Body $text1 -Encoding $encoding -From "robot1@tmn.apkbank.apk" -Subject "Протокол с ошибкой $date1" -SmtpServer 191.168.6.50
	}
}