$put1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

$orig_path = "c:\WORK"
$arch_path = "c:\WORK\ARH"
$ptk_path = "l:\PTK PSD\Post\Post"
$email = @("pozdnyakova@tmn.apkbank.ru", "tmn-goe@tmn.apkbank.ru")
#$orig_path = "c:\Work"
#$arch_path = "$put1\ARH"
#$ptk_path = "$put1\Post"
#$email = @("tmn-goe@tmn.apkbank.ru")

Set-Location $orig_path

$file = @(Get-ChildItem "*.xml")
if ($file.Length -eq 0){
    Write-Host "Файлы не найдены!" -ForegroundColor Red    
    exit
}

$flag_ps = $false
$flag_ft = $false
$mask = ""

$files = @(Get-ChildItem "PS*.xml")
if ($files.Length -ne 0){
    $flag_ps = $true
    $mask = "PSEI*.ARJ"    
}

$files1 = @(Get-ChildItem "FT*.xml")
if ($files1.length -ne 0){
    $flag_ft = $true
    $mask = "KESDT*.ARJ"   
}

$files2 = @(Get-ChildItem "ET*.xml")
if ($files2.length -ne 0){
    $flag_ft2 = $true
    $mask = "KESDT*.ARJ"   
}

$f_name_arj = ""

if ($flag_ps){
    $date1 = Get-Date -UFormat "%Y%m%d"
    $f_name_arj = -join("PSEI_2880_0002_", $date1, "_001")
}

if ($flag_ft){
    $date1 = Get-Date -UFormat "%Y%m%d"
    $f_name_arj = -join("kesdt_2880_0002_", $date1, "_001")
}

if ($flag_ft2){
    $date1 = Get-Date -UFormat "%Y%m%d"
    $f_name_arj = -join("kesdt_2880_0002_", $date1, "_001")
}

Write-Host "Начинаем архивацию..." -ForegroundColor Blue

$AllArgs = @('m', $f_name_arj, '*.xml')
&"$put1\arj32" $AllArgs > $null

$file2 = Get-ChildItem "*.arj"
Write-Host $file2.name -ForegroundColor Blue
$date1 = Get-Date -UFormat "%d%m%Y"
$d_arch_path = -join ("$arch_path", "\", "$date1")

if (!(Test-Path($d_arch_path))){
    New-Item -type directory -path $d_arch_path > $null
}

$f1 = ""

$f_count = @(Get-ChildItem "$d_arch_path\$mask")    
if ($f_count.Length -ne 0){
    $num1 = $f_count.Length + 1
    $num1_s = [String]"{0:000}" -f $num1        
    $f1 = $file2.name -replace "(?<=_)[\d]+(?=\.arj)", $num1_s
    Rename-Item -Path $file2.Name -NewName $f1
}


if ($f1 -ne ""){
    Write-Host "Переименован в $f1" -ForegroundColor Green
}

$encoding = [System.Text.Encoding]::UTF8
$str1 = ""
if ($flag_ps){
    $str1 ="Архив паспорта сделки"
}
if ($flag_ft){
    $str1 ="Архив таможенной декларации"
}
if ($flag_ft2){
    $str1 ="Архив квитанции о непринятии"
}
$str1 = -join ($str1, " ", $date1)
$file3 = Get-ChildItem "*.arj"

Send-MailMessage -from "robot@tmn.apkbank.ru" -to $email -Encoding $encoding -subject $str1 -smtpServer 191.168.6.50 -Attachment $file3.name

Copy-Item "*.arj" -destination $ptk_path
Write-Host "Скопирован в $ptk_path" -ForegroundColor Green

Move-Item "*.arj" -destination $d_arch_path
Write-Host "Перемещён в архив $d_arch_path" -ForegroundColor Green