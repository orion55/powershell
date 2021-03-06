#текущий путь
$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#путь до сайта
$pathSite = "c:\OSPanel\domains\woo.loc"
$pathSql = $pathSite + "\sql"
$mysqlexe = "c:\OSPanel\modules\database\MySQL-5.7-x64\bin\mysql.exe"
$mysql = "c:\OSPanel\modules\database\MySQL-5.7-x64\bin"
$user = "root"
$databasename = "woo"

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
	
	if (!(Test-Path $mysqlexe)){
		Write-Host -ForeGroundColor Red "Файл $destinationDirectory не найден!"
		return $false
	}
	
	return $true	
}

ClearUI
if (!(isCheck)){
	exit
}

Set-Location $pathSite

&git pull origin master

&cmd.exe /c "$mysqlexe -u $user $databasename < $pathSql\dump.sql"
Write-Host -ForegroundColor Green "Экспорт в БД завершён"