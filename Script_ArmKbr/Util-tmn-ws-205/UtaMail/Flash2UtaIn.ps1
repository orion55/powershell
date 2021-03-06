#текущий путь
$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#каталог на флэшке
$pathInFlash = "d:\IN_MAIL"
#настройки почты
$toMail = @("tmn_oit@tmn.apkbank.apk")
$fromMail = "krainevaea@tmn.apkbank.ru"
$smtpHost = "191.168.6.50"

function sendEmail{
	Param ($subject, $body, $attachments)
	
	$email = New-Object System.Net.Mail.MailMessage 
	foreach($mailTo in $toMail){
	    $email.To.Add($mailTo)
	}
	
	foreach($att in $attachments){
		$attachment = new-object System.Net.Mail.Attachment $att
	    $email.Attachments.Add($attachment)
	}
	
	$email.From = $fromMail
	$email.Subject = $subject
	$email.Body = $body
	 
	$client = New-Object System.Net.Mail.SmtpClient $smtpHost
	$client.UseDefaultCredentials = $true
	$client.Send($email)
}

if (!(Test-Path -Path $pathInFlash)){
	exit
}

Clear-Host
Set-Location $pathInFlash

$namesDirectory = Get-ChildItem $pathInFlash -Name
if ($namesDirectory -eq $null){
	try{
		Remove-Item $pathInFlash -ErrorAction Stop -Force
	}
	finally{
		exit
	}
}

foreach ($current in $namesDirectory){
	$currentDir = "$pathInFlash\$current"
	
	$files = Get-ChildItem $currentDir
	
	if ($files -ne $null){
		Write-Host -ForegroundColor Blue "Абонент $current"			
		$currentStrings = @()
		Get-ChildItem "*.*" -Path $currentDir | ForEach-Object -Process { $currentStrings += $_.Fullname; Write-Host -ForegroundColor Green $_.Fullname}
		sendEmail -subject "Пришли сообщения из ГУ ЦБ - абонент $current" -body "Получено через платёжную UTA" -attachments $currentStrings
	}	
}

Write-Host -ForegroundColor Green "Очищаем каталог $pathInFlash"
do{
	try{
		
		Get-ChildItem -Path $pathInFlash -Recurse | Remove-Item -force -recurse -ErrorAction Stop		
		break
	}
	Catch{
		$ErrorMessage = $_.Exception.Message
		$FailedItem = $_.Exception.ItemName
		Write-Host -ForegroundColor DarkBlue $ErrorMessage
		Write-Host -ForegroundColor DarkBlue "Ожидаем 10 секунд..."
		Start-Sleep -Seconds 10
	}
}
until ($false)

try{
	Remove-Item $pathInFlash -ErrorAction Stop -Force
}
Catch{
	$ErrorMessage = $_.Exception.Message
	Write-Host -ForegroundColor DarkBlue $ErrorMessage
}