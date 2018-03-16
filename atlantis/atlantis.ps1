#каталог выполнения скрипта
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#каталог с выходными файлами
$out_dir = "u:"
$atlantis = "ATLANTIS.PRN"
$atlantisFile = "$dir1\$atlantis"

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

Set-Location $dir1

ClearUI

$folders = Get-ChildItem $out_dir | ?{ $_.PSIsContainer } | Select-Object FullName

foreach ($folder in $folders){
	$fld = $folder.FullName
	if (!(Test-Path "$fld\$atlantis")){
		Copy-Item $atlantis $fld
		Write-Host $fld
	}
}