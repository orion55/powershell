#исходный каталог
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
$inFolder = "$dir1\in"


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
	Clear-Host
}

function changeDate($file) {
    Write-host -ForegroundColor green $file
    [xml]$xml = Get-Content $file
    
    $curDate = Get-Date -Format "yyyyMMdd"
    $curDateTwo = Get-Date -Format "dd.MM.yyyy"
    
    $xml.Файл.ИдФайл = $xml.Файл.ИдФайл -replace '20180924', $curDate
    
    $xml.Файл.Документ.ДатаСооб = [string]$curDateTwo
    $xml.Save($file)

    $nameFile = $file -replace '20180924', $curDate
    Rename-Item $file -NewName $nameFile
}

Set-Location $dir1

ClearUI

$xmlFiles = Get-ChildItem "$inFolder\*.xml"
if (($xmlFiles|Measure-Object).count -eq 0){
	exit
}

ForEach ($xmlFile in $xmlFiles) 
{    
    changeDate($xmlFile)
}