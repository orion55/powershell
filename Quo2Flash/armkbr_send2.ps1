#программа копирования файлов из кворума на флешку обычных платежей и копирование из в СМЭВ
#переменные

$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#исходный путь
#$orig_path = "m:\cb_out"
$orig_path = "$dir1\cb_out"

#путь назначения !!!Флешка
#$dest_path = "d:\cli"
$dest_path = "$dir1\cli"

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

function fname($filename){
	$date1 = $filename.LastWriteTime
	$dt = "{0:yyyy}{0:MM}{0:dd}" -f $date1
	$ext1 = $file1.Extension
	$ext1 = $ext1.substring(1, 3)
	$file2 = -join ($dt, $ext1, ".xml")	
	return $file2
}

ClearUI
Write-Host -ForegroundColor White "Запуск скрипта..."

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

Set-Location $orig_path

#находим все файлы имя которых начинается на i
$files = Get-ChildItem "i*.*" -path $orig_path
if ($files -eq $null){
	Write-Host -ForegroundColor Cyan "Файлы $orig_path\i*.* не найдены."
	Read-Host "Нажмите любую клавишу для выхода..."| Out-Null
	Exit
}

foreach ($file1 in $files){
	Write-Host -ForegroundColor Green $file1.fullname

	#копируем файлы на сервер АРК КБР
	Copy-Item $file1 -Destination $dest_path -force	 
	
	#перемещаем файлы в архив
	$file21 = $file1.Name -replace "i", "a"	
	Rename-Item $file1 -NewName $file21 -force
}