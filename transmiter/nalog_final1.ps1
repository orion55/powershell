$put1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#$work2 = "c:\work"
$work2 = "$put1\Work"
#$365p  = "\\tmn-ts-01\311jur\Archive"
$365p  = "$put1\311jur\Archive"
#$ptkpsd1 = "L:\PTK PSD\Post\Post"
$ptkpsd1 = "$put1\Post"

#$email = @("tmn-lov@tmn.apkbank.ru", "tmn_oit@tmn.apkbank.apk")
$email = @("tmn-goe@tmn.apkbank.ru")

Set-Location $work2

. $put1/lib/PSMultiLog.ps1

$dt = Get-Date -Format "dd-MM-yyyy"
$logName = $logDir+ "\" + $dt + "_LOG.log"

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

$mask = "AN06962*.ARJ"

$file = @(Get-ChildItem $mask)
if ($file.Length -eq 0){
    Write-Log -EntryType Error -Message "Файлы не найдены!"
    exit
}
$file2 = Get-ChildItem $mask
Write-Log -EntryType Information -Message $file2.name 

$AllArgs = @('l', $file2)
$var1 = &"$put1\arj32.exe" $AllArgs 
$var1 = $var1 | Select-Object -Last 1

$regex = "(?<=\ ).*(?=\ files)"
$match = [regex]::Match($var1, $regex)
if ($match.Success){
	$kol = [int]$match.Value
}

$dt1 = Get-Date -Format "ddMMyyyy"
$arch_dir = -join ($365p, '\', $dt1)
if (!(Test-Path -Path $arch_dir )){
    Write-Host -EntryType Information -Message "Создаем каталог"
	New-Item -ItemType directory $arch_dir -Force | out-null	
}

$f1 = ""

[int]$f_count = (Get-ChildItem "$arch_dir\$mask" | Measure-Object).Count
if ($f_count -ne 0){
    $num1 = $f_count + 1
    $num1_s = [String]"{0:0000}" -f $num1        
    $f1 = $file2.name -replace "[\d]{4}(?=\.arj)", $num1_s
    Rename-Item -Path $file2.Name -NewName $f1    
}

if ($f1 -ne ""){
    Write-Log -EntryType Information -Message "Переименован в $f1"    
}

Copy-Item $mask -destination $ptkpsd1
Write-Log -EntryType Information -Message "Скопирован в $ptkpsd1"

Move-Item $mask -destination $arch_dir
Write-Log -EntryType Information -Message "Перемещён в архив $arch_dir"

Write-Log -EntryType Information -Message "Отправляем письмо"
$date1 = Get-Date -UFormat "%d%m%Y"
$body1 = "Отправлено $kol файлов"
$encoding = [System.Text.Encoding]::UTF8
Send-MailMessage -To $email -Body $body1 -Encoding $encoding -From "robot_gni@tmn.apkbank.apk" -Subject "Отправка сообщений ГНИ $date1" -SmtpServer 191.168.6.50

Stop-FileLog
Stop-HostLog