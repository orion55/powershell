$api_id = "3D7F0F8B-0C5B-5A08-0585-EB307C9E4835"
$phone = "79129241518"
$textMessage= "Привет мир!"

$baseuri = "http://sms.ru/sms/send"
$uri = New-Object System.Uri ($baseuri + "?api_id=$api_id&to=$phone&text=$textMessage")
$request = Invoke-WebRequest -Uri $uri.AbsoluteUri
if ($request.StatusCode -eq 200){
	Write-Host -ForegroundColor Blue "Сообщение на номер $phone успешно отправлено!"
}