#Программа проверка извещение из ЦБ
#текущий путь
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#каталог с извещениями
$notice_path = "$dir1\OUT"
#$notice_path = "\\3170-file\Quo_L\PTK PSD\Post\ELO\OUT"

#настройка почты
$to = "tmn-goe@tmn.apkbank.apk"
#$to = "tmn-f365@tmn.apkbank.apk"
$from = "tmn-goe@tmn.apkbank.apk"
#$from = "atm_support@tmn.apkbank.apk"
$smtpHost = "191.168.6.50"

#имя лог-файла
$curDate = Get-Date -Format "ddMMyyyy"
$log_path = "$dir1\log"
[string]$logName = $log_path + '\' + $curDate +"_notice.log"

. $dir1/script/PSMultiLog.ps1

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

function Test_dir($dirs1){	
	foreach ($currentPath in $dirs1){
		#проверка существования путей
		if (!(Test-Path -Path $currentPath)){
			Write-Log -EntryType Error -Message "Путь $currentPath не найден!"
			Write-Log -EntryType Information -Message "Нажмите любую клавишу для продолжения" 
			Read-Host "Нажмите Enter"			
			Exit
		}
	}
}

function Create_dir($dirs1){	
	foreach ($currentPath in $dirs1){
		#проверка существования путей
		if (!(Test-Path -Path $currentPath)){
			New-Item -ItemType directory -Path $currentPath | out-Null
		}
	}
}

Set-Location $dir1

ClearUI

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

$dir_arr = @($notice_path)
Test_dir($dir_arr)

$dir_arr = @($log_path)
Create_dir($dir_arr)

$findFiles = Get-ChildItem -Path $notice_path | where { ! $_.PSIsContainer } | Where-Object { $_.Name -match '^IZVTUB_.+[^~]\.xml$' }
$count = ($findFiles|Measure-Object).count

if ($count -eq 0){
	exit
}

Set-Location $notice_path

$flagErr = $false
$bodyMail = ''

ForEach ($file in $findFiles) 
{    
    [string]$xmlDocument = Get-Content $file
    
    $index = $xmlDocument.IndexOf("</Файл>")    
    [xml]$xmlOutput = $xmlDocument.Substring(0, $index + 7)
    
    $xmlTag = $xmlOutput.Файл.ИЗВЦБКОНТР
    if ($xmlTag.КодРезПроверки -ne "01") {
        $flagErr = $true        
    }
    $msg = 'ИмяФайла: '  + $xmlTag.ИмяФайла + ' Результат: ' + $xmlTag.Пояснение
    $bodyMail += $msg + "`r`n"
    
    if ($xmlTag.КодРезПроверки -ne "01") {
        Write-Log -EntryType Error -Message $msg
    } else {
        Write-Log -EntryType Information -Message $msg
    }
    
    $newName = $file.BaseName + '~' + $file.Extension
    Rename-Item $file -NewName $newName
}

$subject = "Извещение о проверке файла сообщения по 440П"
if ($flagErr){
    $subject = 'Ошибка! ' + $subject
}
	
$email = New-Object System.Net.Mail.MailMessage 

$email.To.Add($to)
$email.From = $from
$email.Subject = $subject
$email.Body = $bodyMail
	 
$client = New-Object System.Net.Mail.SmtpClient $smtpHost
#использовать текущий логин\пароль для авторизации на почтовом сервере
$client.UseDefaultCredentials = $true
Try {
    $client.Send($email)
    Write-Log -EntryType Information -Message "Письмо отправленно..."
}
Catch{
    Write-Log -EntryType Information -Message $_.Exception.Message
}

Stop-FileLog
Stop-HostLog