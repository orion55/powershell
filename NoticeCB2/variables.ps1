[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
[boolean]$debug = $true

#каталог с извещениями
[string]$noticePath = "$curDir\OUT"

#рабочий временный каталог
[string]$tmp = "$curDir\temp"

#настройка почты
[string]$440mailAddr = "tmn-goe@tmn.apkbank.ru"
#[string]$440mailAddr = "tmn-f365@tmn.apkbank.apk"
[string]$311mailAddrFiz = "tmn-goe@tmn.apkbank.ru"
#[string]$311mailAddrFiz = "tmn-f311@tmn.apkbank.apk"
$311mailAddrJur = "tmn-goe <tmn-goe@tmn.apkbank.ru>", "lma <lma@tmn.apkbank.ru>"
#[string[]]$311mailAddrJur = "<tmn-lov@tmn.apkbank.ru>", "<tmn_oit@tmn.apkbank.apk>"

[string]$mailServer = "191.168.6.50"
[string]$mailFrom = "atm_support@tmn.apkbank.apk"

#входящие - настройки
[string]$400Mask = "^IZVTUB_.+[^~]\.xml$"
[string]$311Mask = "^UV.+[^~]\.xml$"
[string]$311MaskFiz = "^UVBN.+[^~]\.xml$"
[string]$311MaskJur = "^UVAN.+[^~]\.xml$"

$curDate = Get-Date -Format "ddMMyyyy"
[string]$logPath = "$curDir\log"
#имя лог-файла
[string]$logName = $logPath + '\' + $curDate +"_notice.log"

[string]$spki = "C:\Program Files\MDPREI\spki\spki1utl.exe"
[string]$vdkeys = "d:\SKAD\Floppy\foiv"
[string]$profile = "r2880_2"
[string]$logSpki = $curDir + "\log\" + $curDate + "_spki_tr.log"