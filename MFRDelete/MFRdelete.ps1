#Текущий путь выполнения программы
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#исходный путь
$origPath = "$dir1\MFROUT"

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

Set-Location $origPath
ClearUI
Write-Host -ForegroundColor White "Удаление МФР"

#проверка существования путей
if (!(Test-Path -Path $origPath)){
	Write-Host -ForegroundColor Red "Путь $origPath не найден!"	
	Exit
}

$710Files = Get-ChildItem "$origPath\710*.962"
if (($710Files|Measure-Object).count -gt 0){
	Remove-Item "$origPath\710*.962" -Force
	Write-Host -ForegroundColor Cyan "Файлы успешно удалены!"
} else {
	Write-Host -ForegroundColor Red "Файлы $origPath\710*.962 не найдены!"	
}

Set-Location $dir1
Read-Host "Нажмите любую клавишу для выхода..."| Out-Null