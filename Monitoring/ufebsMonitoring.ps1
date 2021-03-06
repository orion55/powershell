#текущий путь выполнения скрипта
$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#каталог исходных файлов для проверки
$sourceDirectory = "\\191.168.6.12\quorum\TMN\SENDDOC\CB_IN"
#$sourceDirectory = "$currentPath\CB_IN"

#разница в минутах, которая считается, что автомат Ufebs не работает
$intervalMinute = 10

#email для отправки сообщения об ошибке
$to = @("tmn_oit@tmn.apkbank.apk", "krainevaea@tmn.apkbank.ru")
#$to = @("tmn-goe@tmn.apkbank.ru")

#флаг сообщения об ошибке
$flagError = $false

Clear-Host
Set-Location $currentPath

$findFiles = Get-ChildItem -Path $sourceDirectory -Exclude "*.~??" | where { ! $_.PSIsContainer }
$count = ($findFiles|Measure-Object).count

if ($count -eq 0){
	exit
}

$nowDate = Get-Date
foreach ($currentFile in $findFiles){
	$currentDateFile = $currentFile.LastAccessTime
	$differenceTime = New-TimeSpan -Start $currentDateFile -End $nowDate
	if ($differenceTime.TotalMinutes -ge $intervalMinute){
		$flagError = $true
	}
}

if ($flagError){
	$body = "Файлы $sourceDirectory не обработаны. Проверьте автомат Уфэбс! На компьютере tmn-ws-205."
	Write-Host -ForegroundColor Red "Ошибка! $text1"
		
	Write-Host "Отправляем письмо..." -ForegroundColor Green

	$subject = "Ошибка отправки файлов в ЦБ - $nowDate"
	$from = "oit-mrf@tmn.apkbank.apk"
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
	
	Write-Host "Письмо отправленно..." -ForegroundColor Green
}