Import-Module International

$1 = New-WinUserLanguageList en-US
$1.Add("ru-RU")
Set-WinUserLanguageList $1 -force