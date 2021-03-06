$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
[string]$profit = "$dir1\profit"
[string]$backup = "$profit\backup"
[string]$out = "$dir1\out"
$email = @("tmn-goe@tmn.apkbank.ru")
#имя лог-файла
[string]$logName = (Get-Item $PSCommandPath ).DirectoryName + "\log\balans.log"

. $dir1/PSMultiLog.ps1

function ClearUI{
	$bckgrnd = "DarkBlue"
	$Host.UI.RawUI.BackgroundColor = $bckgrnd
	$Host.UI.RawUI.ForegroundColor = 'White'
	$Host.PrivateData.ErrorForegroundColor = 'Red'
	$Host.PrivateData.ErrorBackgroundColor = $bckgrnd
	$Host.PrivateData.WarningForegroundColor = 'Magenta'
	$Host.PrivateData.WarningBackgroundColor = $bckgrnd
	$Host.PrivateData.DebugForegroundColor = 'Yellow'
	$Host.PrivateData.DebugBackgroundColor = $bckgrnd
	$Host.PrivateData.VerboseForegroundColor = 'Green'
	$Host.PrivateData.VerboseBackgroundColor = $bckgrnd
	Clear-Host
}

function Test_dir($dirs1){	
	foreach ($d1 in $dirs1){
		#проверка существования путей
		if (!(Test-Path -Path $d1)){
			Write-Host "Путь $d1 не найден!" -ForegroundColor Red
			Write-Host "Нажмите любую клавишу для продолжения" 
			Read-Host "Нажмите Enter"			
			Exit
		}
	}
}

ClearUI
Set-Location $profit

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

$dir_arr = @($profit, $backup, $out)
Test_dir($dir_arr)

$oxa = Get-ChildItem -Path $profit "*.oxa"
$count_oxa = ($oxa | Measure-Object).count
Write-Log -EntryType Information -Message "Найдено $count_oxa файл(а) в $profit!"
if ($count_oxa -eq 0){
    exit
}
Write-Log -EntryType Information -Message ($oxa.Name | Out-String)

foreach ($f in $oxa){
	$newname = $f.FullName -replace "oxa","txt"
	Copy-Item $f -Destination $newname
}

try {
    $msg = Move-Item -Path "$profit\*.txt" -Destination $out -ErrorAction Stop -Verbose -Force *>&1    
    Write-Log -EntryType Information -Message ($msg | Out-String)  
    Write-Log -EntryType Information -Message "Файл(ы) перенесен(ы) в $out"
}
catch {
    Remove-Item "$profit\*.txt"
    Write-Log -EntryType Error -Message "Ошибка переноса файла (ов) в $out"
    exit
}

try {
    $msg = Move-Item -Path "$profit\*.oxa" -Destination $backup -ErrorAction Stop -Verbose -Force *>&1
    Write-Log -EntryType Information -Message "Файл(ы) перенесен(ы) в архив $backup"
}
catch {
    Write-Log -EntryType Error -Message "Ошибка переноса файла (ов) в $backup"
    exit
}

Write-Log -EntryType Information -Message "Отправляем письмо!"

$days = @()
$year1 = (Get-Date).year
foreach ($d1 in $oxa){
	$d = $d1.Name
	$day1 = $d.Substring(6, 2)	
	$mon1 = $d.Substring(4, 2)
	$days += -join($day1, ".", $mon1, ".", $year1)
}
$dt1 = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
$encoding = [System.Text.Encoding]::UTF8
$text1 = "Баланс успешно отправлен!"
$text1 = -join ($text1, $days | Out-String)

try {
    Send-MailMessage -To $email -Body $text1 -Encoding $encoding -From "robot_bal@tmn.apkbank.apk" -Subject "Баланс успешно отправлен! - $dt1" -SmtpServer 191.168.6.50 -ErrorAction Stop
}
catch {
    Write-Log -EntryType Error -Message "Ошибка отправки письма"    
}

Stop-FileLog
Stop-HostLog