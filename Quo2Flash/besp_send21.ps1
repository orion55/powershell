#программа копирования файлов из кворума на флешку БЭСП-платежей и копирование из в СМЭВ
#переменные
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#исходный путь
#$orig_path = "m:\cb_out\BESP"
$orig_path = "$dir1\cb_out\BESP"

#путь назначения
#$dest_path = "d:\cli"
$dest_path = "$dir1\cli"

#exp путь
#$exp_path = "m:\cb_out\BESP\exp"
$exp_path = "$dir1\cb_out\BESP\exp"

#путь московского сервера
#$mosk_path = "\\191.168.7.14\store\СМЭВ\TUMEN\IN"
#$mosk_path_two = "\\191.168.7.14\store\gis_hcs\TMN\IN"
#$user1 = "tmn\tmn-svc_smev"
#$pass1 = "ep6UN!vB0n"
$mosk_path = "\\192.168.72.17\disk_O\test1"
$mosk_path_two = "\\192.168.72.17\disk_O\test2"
$user1 = "tmn\admsrv"
$pass1 = "99ty95q(Ls"

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
	$Host.PrivateData.ProgressForegroundColor = 'Cyan'
	$Host.PrivateData.ProgressBackgroundColor = $bckgrnd
	Clear-Host
}

Import-Module BitsTransfer
ClearUI
Write-Host -ForegroundColor White "Запуск скрипта..."

#проверка существования путей
#проверка существования путей
if (!(Test-Path -Path $orig_path)){
	Write-Host -ForegroundColor Red "Путь $orig_path не найден!"
	Read-Host "Нажмите любую клавишу для выхода..."| Out-Null
	Exit
}

if (!(Test-Path -Path $dest_path)){
	Write-Host -ForegroundColor Red "Путь $dest_path не найден! Проверьте флешку!"
	Read-Host "Нажмите любую клавишу для выхода..."| Out-Null
	Exit	
}

if (!(Test-Path -Path $exp_path)){
	Write-Host -ForegroundColor Red "Путь $exp_path не найден!"
	Read-Host "Нажмите любую клавишу для выхода..."| Out-Null
	Exit
}

function fname($filename){
	$date1 = $filename.LastWriteTime
	$dt = "{0:yyyy}{0:MM}{0:dd}" -f $date1
	$ext1 = $file1.Extension
	$ext1 = $ext1.substring(1, 3)
	$file2 = -join ($dt, $ext1, "b.xml")
	return $file2
}

Set-Location $orig_path

$Password = ConvertTo-SecureString $pass1 -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential($user1, $Password)

#находим все файлы имя которых начинается на p
$files = Get-ChildItem "p*.*" -path $orig_path
if ($files -eq $null){
	Write-Host -ForegroundColor Cyan "Файлы $orig_path\p*.* не найдены."
	Read-Host "Нажмите любую клавишу для выхода..."| Out-Null
	Exit
}

#основные операции создания копии, переименования
Copy-Item "p*.*" -Destination $dest_path
Get-ChildItem "p*.*" | Rename-Item -NewName { $_.name -replace "p", "b" }
Copy-Item "b*.*" -Destination $exp_path

$files = Get-ChildItem "b*.*" -path $orig_path
foreach ($file1 in $files){
	Write-Host -ForegroundColor Green $file1.fullname

	#копируем файлы на московский сервер 
	$file21 = fname($file1)		
	Copy-Item $file1 -Destination $file21

	#копируем файлы на московский сервер
	$job = Start-BitsTransfer –source $file21 -destination $mosk_path -Authentication NTLM -Credential $mycreds -asynchronous -Priority low	
	while( ($job.JobState.ToString() -eq 'Transferring') -or ($job.JobState.ToString() -eq 'Connecting') )
	{
		Sleep 3		
	}	
	Complete-BitsTransfer -BitsJob $job
	
	$job = Start-BitsTransfer –source $file21 -destination $mosk_path_two -Authentication NTLM -Credential $mycreds -asynchronous -Priority low
	while( ($job.JobState.ToString() -eq 'Transferring') -or ($job.JobState.ToString() -eq 'Connecting') )
	{
		Sleep 3
	}
	Complete-BitsTransfer -BitsJob $job
}

Remove-Item "$orig_path\b*.*"
Remove-Item "$orig_path\*.xml"