#Текущий путь выполнения программы
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#исходный путь
$origPath = "$dir1\OUT"

#путь московсого сервера
$destPath = "$dir1\BinkOut"

#список для отправки почты
#$to = @("tmn_oit@tmn.apkbank.apk", "krainevaea@tmn.apkbank.ru")
$to = @("tmn-goe@tmn.apkbank.ru")

#Очищаем экран и устанавливаем цвета
function ClearUI{
	$bckgrnd = "DarkBlue"
	$Host.UI.RawUI.BackgroundColor = $bckgrnd
	$Host.UI.RawUI.ForegroundColor = 'White'
	$Host.PrivateData.ErrorForegroundColor = 'Red'
	$Host.PrivateData.ErrorBackgroundColor = $bckgrnd
	$Host.PrivateData.WarningForegroundColor = 'Magenta'
	$Host.PrivateData.WarningBackgroundColor = $bckgrnd
	$Host.PrivateData.DebugForegroundColor = 'Yellow'
	$Host.PrivateData.DebugBackgroundColor = $bckgrnd
	$Host.PrivateData.VerboseForegroundColor = 'Green'
	$Host.PrivateData.VerboseBackgroundColor = $bckgrnd
	$Host.PrivateData.ProgressForegroundColor = 'Cyan'
	$Host.PrivateData.ProgressBackgroundColor = $bckgrnd
	Clear-Host
}

Set-Location $origPath
ClearUI

#проверка существования путей
if (!(Test-Path -Path $origPath)){
	Write-Host -ForegroundColor Red "Путь $origPath не найден!"	
	Exit
}

if (!(Test-Path -Path $destPath)){
	Write-Host -ForegroundColor Red "Путь $destPath не найден!"	
	Exit
}

$257Files = Get-ChildItem "$origPath\*.257"
if (($257Files|Measure-Object).count -gt 0){
	Copy-Item "$origPath\*.257" -Destination $destPath
	Write-Host -ForegroundColor Cyan "Файлы $origPath\*.257 успешно скопированы!"
} else {
	Write-Host -ForegroundColor Red "Файлы $origPath\*.257 не найдены!"	
	Exit
}

$nowDate = Get-Date
$body = "Отчет по форме 257 успешно отправлен"
$subject =  -join($body, " - ", $nowDate)
$from = "tmn-goe@tmn.apkbank.apk"
$smtpHost = "191.168.6.50"
	
$email = New-Object System.Net.Mail.MailMessage 
foreach($mailTo in $to){
    $email.To.Add($mailTo)
}
 
$email.From = $from
$email.Subject = $subject
$email.Body = $body
	 
$client = New-Object System.Net.Mail.SmtpClient $smtpHost
#использовать текущий логин\пароль для авторизации на почтовом сервере
$client.UseDefaultCredentials = $true
$client.Send($email)

Set-Location $dir1