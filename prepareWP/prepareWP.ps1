#текущий путь
$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#путь до сайта
$pathSite = "c:\OpenServer\domains\firstledi.dev"
$pathSql = $pathSite + "\src\sql"
$mysqldump = "c:\OpenServer\modules\database\MariaDB-10-x64\bin\mysqldump.exe"
$mysql = "c:\OpenServer\modules\database\MariaDB-10-x64\bin"
$7z = "d:\Util\Total7zip\7z.exe"
$user = "root"
$databasename = "first"

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

function isCheck{	
	if (!(Test-Path $pathSql)){
		Write-Host -ForeGroundColor Red "Каталог $pathSql не найден!"
		return $false
	}
	
	if (!(Test-Path $mysqldump)){
		Write-Host -ForeGroundColor Red "Файл $destinationDirectory не найден!"
		return $false
	}
	
	
	if (!(Test-Path $7z)){
		Write-Host -ForeGroundColor Red "Файл $7z не найден!"
		return $false
	}
	return $true	
}

ClearUI
if (!(isCheck)){
	exit
}
Set-Location $pathSql

$files = Get-ChildItem "*.sql"
if (($files|Measure-Object).count -gt 0){
	Remove-Item "*.sql" -Force
	Write-Host -ForegroundColor Cyan "Файлы *.sql успешно удалены!"
}

$files = Get-ChildItem "*.zip"
if (($files|Measure-Object).count -gt 0){
	Remove-Item "*.zip" -Force
	Write-Host -ForegroundColor Cyan "Файлы *.zip успешно удалены!"
}

$argList = "-Q -c -e -u$user $databasename -r $pathSql\dump.sql"
$mysqldumpProc = Start-Process -FilePath $mysqldump -ArgumentList $argList -Wait -Passthru 	
if ($mysqldumpProc.ExitCode -eq 0) {  
	Write-Host -ForeGroundColor Cyan "Успешный экспорт из БД!"
} else {
	Write-Host -ForeGroundColor Red "Ошибка экспорта из БД"
	exit
}

$dt = Get-Date -Format "dd-MM-yyyy"
$argList = "a -tzip dump$dt.zip dump.sql"
$7zProc = Start-Process -FilePath $7z -ArgumentList $argList -Wait -Passthru 	
if ($7zProc.ExitCode -eq 0) {  
	Write-Host -ForeGroundColor Cyan "Успешная архивация!"
} else {
	Write-Host -ForeGroundColor Red "Ошибка архивации БД"
	exit
}

$files = Get-ChildItem "*.sql"
if (($files|Measure-Object).count -gt 0){
	Remove-Item "*.sql" -Force	
}

Set-Location $pathSite
& git add -A
$dt1 = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
$msg = """Auto commit $dt1"""
& git commit -m $msg