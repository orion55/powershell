[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
. $curDir/variables.ps1
. $curDir/lib.ps1

$docPath = "$curDir\doc"
$miscPath = "$curDir\misc"

$hashList =@{
    "MAIL" = "";
    "QUORUM" = "";
    "RETAIL" = "";
    "CRM" = "";
    "WAY" = "";
    "SUVD" = "";
    "KK" = "";
}

function mailSend(){	
    Param(	    
        [string]$hash
    )
    
    $title = "Новый пользователь $fullName"    
    [string]$emailTo = (Get-Variable -Name email$($hash.ToUpper())).Value
    [string]$textMail = (Get-Variable -Name text$($hash.ToUpper())).Value
    
    $sign = Get-Content "$miscPath\sign.txt" -Encoding UTF8
    
    $signBr = ''
    foreach ($line in $sign){
        $signBr += $line + "<br>"
    } 
    
    $body = @"
<body>
Здравствуйте!<br><br>
$textMail
<br><br>
$signBr
</body>
"@

    try {
        Send-MailMessage -body $body -Subject $title -from $mailFrom -to $emailTo -SmtpServer $mailSMTP -Encoding $([System.Text.Encoding]::UTF8) -BodyAsHtml -Attachments $hashList[$hash] -Cc $mailCC
        Write-Host "Сообщение успешно отправлено $emailTo" -ForegroundColor Yellow
    }
    catch { 
        Write-Host $_.Exception.Message -ForegroundColor Red   
    }
    
}

Set-Location $curDir

ClearUI

testDir(@($docPath, $miscPath))

$pdfFiles = Get-ChildItem -Path $docPath "*.pdf"
$pdfCount = ($pdfFiles | Measure-Object).count
Write-Host -ForegroundColor Green "Найдено $pdfCount файл(а) в $docPath!"
if ($pdfCount -eq 0){
    exit
}

foreach ($key in $($hashList.keys)) {
    $curFile = Get-ChildItem -Path $docPath "*_$key.pdf"
    if (($curFile | Measure-Object).count -gt 0){
        $hashList[$key] = $curFile.FullName
    }    
}

foreach ($key in $($hashList.keys)) {
    if ($hashList[$key] -ne ''){
        mailSend -hash $key
    }
}
