[string]$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#рабочий каталог, где будут подписываться и шифроваться файлы
[string]$work = "$dir1\src\work"

#скрипты для подписи и шифрования
[string]$scripts = "$dir1\scripts"
[string]$script_unsig = "$scripts\440UnSign.scr"
[string]$script_uncrypt = "$scripts\440UnCript.scr"
[string]$script_sig = "$scripts\send440Sign.scr"
[string]$script_crypt = "$scripts\send440Cript.scr"

#дискеты для подписи и шифрования
[string]$disk_sig = "C:\DISKET2017\disk\disk22"
[string]$disk_crypt = "c:\DISKET2017\Disk\DISK21"
[string]$disk_sig_send = "c:\DISKET2016-1\Disk\DISK2"

#путь до программы шифрования и архиватор
[string]$verba = "c:\Program Files\MDPREI\РМП Верба-OW\FColseOW.exe"
[string]$arj32 = "$dir1\util\arj32.exe"

#каталог на московском сервере, с отчетами для налоговой
[string]$arm440 = "$dir1\src\ARM_440"
[string]$arm440_ul = "$arm440\ANSWER_UL"
[string]$arm440_fl = "$arm440\ANSWER_FL"

#настройка почты
[string]$mail_addr = "tmn-goe@tmn.apkbank.ru"
[string]$mail_server = "191.168.6.50"
[string]$mail_from = "atm_support@tmn.apkbank.apk"

#входящие - настройки
[string]$incoming_out = "$dir1\src\out"
[string]$incoming_files = "AFN_MIFNS00_7106962_*_000??.ARJ"
[string]$outcoming_post = "$dir1\src\post"

#архив
[string]$440p_arhive = "$dir1\src\440p\Arhive"
[string]$440p_ack = "$dir1\src\440p\ack"
[string]$440p_err = "$dir1\src\440p\error"

#комита
[string]$comita_in = "$dir1\src\bank"

#имя лог-файла
[string]$logName = (Get-Item $PSCommandPath ).DirectoryName + "\log\form440p.log"

#Каталог XSD-схем
[string]$schemaCatalog = "$dir1\xsd-schemas"