#Программа перемещения в архив файлов, которые уже отработаны автоматом УФЭБС
#текущий файл
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#исходный каталог

$besp_path = "$dir1\exp"
#$besp_path = "\\191.168.6.12\quorum\TMN\SENDDOC\CB_OUT\BESP\exp"

$besp_archive = "$besp_path\ARCHIVE"

#$sourceDirectory = "$currentPath\CB_IN"
#$sourceDirectory = "w:\CB_IN"
#каталог архива
#$destinationDirectory = "$currentPath\CB_IN\ARCHIVE"
#$destinationDirectory = "w:\CB_IN\ARCHIVE"

#имя лог-файла
$curDate = Get-Date -Format "ddMMyyyy"
$log_path = "$dir1\log"
[string]$logName = $log_path + '\' + $curDate +"_besp.log"

. $dir1/script/PSMultiLog.ps1

#Очищаем экран и устанавливаем цвета
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

function Test_dir($dirs1){	
	foreach ($d1 in $dirs1){
		#проверка существования путей
		if (!(Test-Path -Path $d1)){
			Write-Log -EntryType Error -Message "Путь $d1 не найден!"
			Write-Log -EntryType Information -Message "Нажмите любую клавишу для продолжения" 
			Read-Host "Нажмите Enter"			
			Exit
		}
	}
}

function Create_dir($dirs1){	
	foreach ($d1 in $dirs1){
		#проверка существования путей
		if (!(Test-Path -Path $d1)){
			New-Item -ItemType directory -Path $d1 | out-Null
		}
	}
}

Set-Location $dir1

ClearUI

Write-Host -ForegroundColor White "Запуск скрипта..."
Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

$dir_arr = @($besp_path)
Test_dir($dir_arr)

$nowDate = Get-Date -f 'dd.MM.yyyy'
$dateDirectory = $besp_archive + '\' + $nowDate

$dir_arr = @($log_path, $besp_archive, $dateDirectory)
Create_dir($dir_arr)

$findFiles = Get-ChildItem "b*.!??" -Path $besp_path | where { ! $_.PSIsContainer }
$count = ($findFiles|Measure-Object).count

if ($count -eq 0){
	exit
}

Set-Location $besp_path
$msg = Move-Item $findFiles -Destination $dateDirectory -Verbose -Force *>&1
Write-Log -EntryType Information -Message ($msg | Out-String)

Stop-FileLog
Stop-HostLog