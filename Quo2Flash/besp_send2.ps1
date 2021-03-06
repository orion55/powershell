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
	Write-Host -ForegroundColor Red "Путь $dest_path не найден! Проверьте флешку!!!"
	Read-Host "Нажмите любую клавишу для выхода..."| Out-Null
	Exit	
}

if (!(Test-Path -Path $exp_path)){
	Write-Host -ForegroundColor Red "Путь $exp_path не найден!"
	Read-Host "Нажмите любую клавишу для выхода..."| Out-Null
	Exit
}

Set-Location $orig_path

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

Remove-Item "$orig_path\b*.*"
Write-Host -ForegroundColor White "Конец работы скрипта..."