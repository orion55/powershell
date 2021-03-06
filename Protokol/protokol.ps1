#программа копирования файлов АРМ КБР с флешки в кворум
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

$protokol_file = "$dir1\ProtocolDMP2.txt"
$xml_name = "$dir1\LSOZ_2880_0002_F20151201_L20161130_C20161202_000.xml"

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
Write-Host -ForegroundColor White "Анализ лога"
Remove-Item "$dir1\file1.txt"
Remove-Item "$dir1\result.txt"

[xml]$xml = Get-Content $xml_name

[String]$file = Get-Content $protokol_file -Raw
$regex = [regex] "Запись\ №\ [0-9]*\ \(файл[\w\W]*?(?=Запись\ №\ [0-9]*\ \(файл)"
$matches = ($regex).Matches($file);

foreach ($match in $matches){
	if ($match.value -match 'НЕСООТВЕТСТВИЕ.*иностранной\ организации\.'){
	#if ($match.value -match 'СУЩЕСТВЕННОЕ НЕСООТВЕТСТВИЕ'){
		$match.value | Out-File "$dir1\file1.txt" -Encoding UTF8 -Append
		
		$regex1 = [regex] "(?<=,\ запись\ №\ ).*(?=\))"
		$matches1 = ($regex1).Matches($match.value);

		$path = "/TRANSPORT/Table/Rec[@RecID=$matches1]"		
		$xml_node = $xml.SelectNodes($path)
		$xml_node.ACCOUNT
		$xml_node.TNAME
		$xml_node.ACCOUNT + " " + $xml_node.TNAME | Out-File "$dir1\result.txt" -Encoding UTF8 -Append
	}
}
