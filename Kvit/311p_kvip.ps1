$orig_dir = "\\3170-file\Quo_L\PTK PSD\Post\ELO\OUT"
$arch_dir = "\\tmn-ts-01\311p\Arhive"
$arch_dir2 = "\\191.168.7.14\rbs\tmn\311p\rbs\kvit1"
$email = "tmn-f311@tmn.apkbank.apk"

Clear-Host
Set-Location $orig_dir
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

Write-Host -ForegroundColor Green "Ищем квитанции по 311p..."

$nn = Get-ChildItem "nn*.arj"
if ($nn -eq $null){
	exit
}

Write-Host -ForegroundColor Green "Создаем каталоги"
$dt1 = Get-Date -Format "ddMMyyyy"
$arch_dir = -join ($arch_dir, '\', $dt1)
if (!(Test-Path -Path $arch_dir )){
	New-Item -ItemType directory $arch_dir -Force | out-null	
}

$arch_dir_kvit = -join ($arch_dir, '\', 'KVIT')
if (!(Test-Path -Path $arch_dir_kvit )){
	New-Item -ItemType directory $arch_dir_kvit -Force | out-null	
}

$arch_dir_kvit2 = -join ($arch_dir2, '\', $dt1)
if (!(Test-Path -Path $arch_dir_kvit2 )){
	New-Item -ItemType directory $arch_dir_kvit2 -Force | out-null	
}

$tmp_dir = "$dir1\tmp"
if (!(Test-Path -Path $tmp_dir )){
	New-Item -ItemType directory $tmp_dir -Force | out-null	
} else {
	Remove-Item $tmp_dir -Force -Recurse
	New-Item -ItemType directory $tmp_dir -Force | out-null	
}

Write-Host -ForegroundColor Green "Разархивирем во временный каталог"
foreach ($n1 in $nn){
	$AllArgs = @('e', $n1, $tmp_dir)
	&"$dir1\arj32.exe" $AllArgs > $null
}

Set-Location $tmp_dir
[int]$all_count = (Get-ChildItem "*.xml" | Measure-Object).Count
[int]$err_count = (Get-ChildItem "SFE*.xml" | Measure-Object).Count
[int]$other_count = (Get-ChildItem "SFF*.xml" | Measure-Object).Count

Write-Host -ForegroundColor Green "Копируем файлы"
Set-Location $orig_dir
Copy-Item "$tmp_dir\*.xml" -Destination $arch_dir_kvit
Copy-Item "$tmp_dir\*.xml" -Destination $arch_dir_kvit2
Copy-Item -Path "nn*.arj" -Destination $arch_dir
Remove-Item -Path "nn*.arj"

Remove-Item $tmp_dir -Force -Recurse

Write-Host -ForegroundColor Green "Отправляем письмо"
$body1 = "Пришли квитанции из ЦБ по форме 311p`n`nВсего: $all_count`nПринято: $other_count`nОшибки: $err_count`n`n Каталог с квитанциями - $arch_dir_kvit"
$encoding = [System.Text.Encoding]::UTF8
Send-MailMessage -To $email -Body $body1 -Encoding $encoding -From "robot311@tmn.apkbank.apk" -Subject "Квитанции 311p $dt1" -SmtpServer 191.168.6.50