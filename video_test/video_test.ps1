#программа проверки доступности видеорегистраторов по списку (список в файле video.txt)

Clear-Host

$put1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
Set-Location $put1

$file = "$put1\video.txt"
$video = Import-Csv $file -Header "Ip", "Name" -Delimiter ";"
$err = ""

foreach ($vid in $video)
{	
	if (test-Connection $vid.Ip -Count 3 -Quiet)
	{
		Write-Host $vid.Ip  "-" $vid.Name "успешное соединение" -ForegroundColor Green
	}
	else
	{
		$txt = -join ($vid.Ip, " - ", $vid.Name, " соединение не установленно")
		Write-Host $txt -BackgroundColor Red
		$err = -join ($err, "$(Get-Date): $txt", "`n")
	}
}

if ($err -ne ""){
	$encoding = [System.Text.Encoding]::UTF8
	Send-MailMessage -from "robot@tmn.apkbank.ru" -to "tmn-goe@tmn.apkbank.apk", "tmn-pov@tmn.apkbank.apk" -Encoding $encoding -subject "Видеорегистраторы ошибка связи" -body $err -smtpServer 191.168.6.50	
}