#Программа мониторинга состояния виртуальных машин
#текущий путь
$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#файл с именами виртуальных машин
$listFile = "$currentPath\list.txt"

#Api индентификатор
$api_id = "3D7F0F8B-0C5B-5A08-0585-EB307C9E4835"
#номер телефона
$phone = "79129241518"

Clear-Host
Set-Location $currentPath

$flagSMS = $false
$textMessage = ""

$VM = Get-Content $listFile
foreach ($nameVM in $VM){
	$currentVM = Get-VM -name $nameVM
    if ($currentVM.State -eq "Off"){
        Write-Host -ForegroundColor Red "Виртуальная машина $nameVM - отключена."
        $textMessage += "$nameVM - Off`n"
        $flagSMS = $true
    }
    if ($currentVM.State -eq "Running"){
        Write-Host -ForegroundColor Green "Виртуальная машина $nameVM - активна."
    }
}

if ($flagSMS){
    $baseuri = "http://sms.ru/sms/send"
    $uri = New-Object System.Uri ($baseuri + "?api_id=$api_id&to=$phone&text=$textMessage")
    $request = Invoke-WebRequest -Uri $uri.AbsoluteUri
    if ($request.StatusCode -eq 200){
	    Write-Host -ForegroundColor Blue "Сообщение на номер $phone успешно отправлено!"
    }    
}

