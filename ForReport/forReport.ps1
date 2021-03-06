#Текущий путь выполнения программы
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#исходный путь
$origPath = "$dir1\Work"

#путь московсого сервера
$destPath = "$dir1\BinkOut"

#путь архива
$archivPath = "$dir1\Archiv"

#список для отправки почты
#$to = @("tmn_oit@tmn.apkbank.apk", "oo-mya@tmn.apkbank.ru")
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
if (!(Test-Path -Path $archivPath)){
	Write-Host -ForegroundColor Red "Путь $archivPath не найден!"	
	Exit
}

$fo2Files = Get-ChildItem "$origPath\PN*.fo2"
if (($fo2Files|Measure-Object).count -gt 0){
	Copy-Item "$origPath\PN*.fo2" -Destination $destPath
	Move-Item "$origPath\PN*.fo2" -Destination $archivPath
	Write-Host -ForegroundColor Cyan "Файлы $origPath\PN*.fo2 успешно скопированы и помещены в архив!"
} else {
	Write-Host -ForegroundColor Red "$origPath\PN*.fo2 не найдены!"	
	Exit
}

$nowDate = Get-Date
$body = "Отчет ФОР успешно отправлен"
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