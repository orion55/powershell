$to = @("tmn-goe@tmn.apkbank.ru")
$from = "krainevaea@tmn.apkbank.apk"
$smtpHost = "191.168.6.50"

$subject = "Ping-pong"
$body = "Hi Ping-pong!"

#Clear-Host
$email = New-Object System.Net.Mail.MailMessage 
foreach($mailTo in $to){
    $email.To.Add($mailTo)
}
 
$email.From = $from
$email.Subject = $subject
$email.Body = $body
 
$client = New-Object System.Net.Mail.SmtpClient $smtpHost
$client.UseDefaultCredentials = $true
$client.Send($email)