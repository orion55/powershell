[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#временный каталог
[string]$tmp = "$curDir\temp"

#настройка почты
[string]$mailAddr = "tmn-f365@tmn.apkbank.apk"
#[string]$mailAddr = "tmn-goe@tmn.apkbank.ru"
#[string]$mailAddr = "tmn_oit@tmn.apkbank.apk"
[string]$mailServer = "191.168.6.50"
[string]$mailFrom = "atm_support@tmn.apkbank.apk"

#архив
[string]$440Arhive = "$tmp\440p\Arhive"
[string]$outPath = "$tmp\OUT"

#маски
[string]$outgoingFilesArj = "AFN_7102803_MIFNS00_*_000??.ARJ"
[string]$outgoingFilesXml = "*_*7102803_*.xml"

#имя лог-файла
[string]$logDir = $curDir + "\log"
[string]$logName = "$logDir\checkArchive.log"