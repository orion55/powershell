#каталог выполнения скрипта
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#каталог с выходными файлами
$out_dir = "$dir1\out"
#каталог с sql-скриптом
$sql_dir = "$dir1\sql"
$exec = "$sql_dir\rko.bat"
$xlsxIp = "$out_dir\ip.xlsx"
$xlsxNotIp = "$out_dir\organization.xlsx"

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
	if (!(Test-Path $sql_dir)){
		Write-Host -ForegroundColor Red "Папка $sql_dir не найдена!"
		return $false
	}
	
	if (!(Test-Path $exec)){
		Write-Host -ForegroundColor Red "Скрипт $exec не обнаружен!"
		return $false
	}
	
	if (!(Test-Path $out_dir)){
		New-Item -ItemType directory $out_dir -Force | out-null		
	} else {
		Remove-Item -Path $out_dir -Include *.* -Force -Recurse
	}
	
	return $true	
}

function exportXlsx{
	Param ($csvName, $xlsxName)
	$csv = Import-Csv -Path $csvName -Delimiter ";"
	
	Write-Host "Экспортируем в $xlsxName" -ForegroundColor Green	
	
	$xl = New-Object -COM "Excel.Application"
	$xl.Visible = $false

	$wb = $xl.Workbooks.Add()
	$ws = $wb.Sheets.Item(1)

	$ws.Cells.NumberFormat = "@"	

	$size = $csv.Length
	
	#Делаем шапку таблицу полужирной
	$i = 1
	$j = 1
	foreach ($prop in $csv[0].PSObject.Properties){
		$ws.Cells.Item($i, $j) = $prop.Name
		$ws.Cells.Item($i, $j).Font.Bold = $True
		$j++
	}
	
	#Заполняем таблицу данными из csv - файла
	$i++
	$csv | Foreach-Object { 
		$j = 1
		foreach ($prop in $_.PSObject.Properties)
		{
			if ($j -eq 4){
				$ws.Cells.Item($i, $j).NumberFormat = '# ##0,00'
				$ws.Cells.Item($i, $j).Value2 = [int]$prop.Value			
				
			} else {
	        	$ws.Cells.Item($i, $j).Value2 = $prop.Value
			}		
		    $j++
		}
    $i++
	}
	
	$objRange = $ws.UsedRange 
	[void] $objRange.EntireColumn.Autofit() 
	
	$wb.SaveAs($xlsxName, 51)
	$wb.Close($false)

	$xl.Quit()
	[System.Runtime.Interopservices.Marshal]::ReleaseComObject($xl) > $null	
	Remove-Variable xl
	Write-Host "Конец экспорта в $xlsxName" -ForegroundColor Green	
}

Set-Location $sql_dir

ClearUI

if (!(isCheck)){	
	exit
}

$rko = "$sql_dir\rko.txt"
if (Test-Path $rko){
	Remove-Item $rko
}

$proc = Start-Process $exec -Wait -Passthru 	
if ($proc.ExitCode -ne 0) {  
	Write-Host -ForeGroundColor Red "Ошибка при работе скрипта $exec"
	exit
}	

#фильтруем - убираем шапку и хвост таблицы
Write-Host "Фильтрация $rko" -ForegroundColor Green	
$content = Get-Content $rko
$num = $content.Length;

$aaa = "$sql_dir\aaa.txt"
if (Test-Path $aaa){
	Remove-Item $aaa
}

$lex = @("------------------------------------------------", "Выбрано строк:")

$flag = $false
for ($i = 0; $i -lt $num; $i++){
	$line = $content[$i];	
		
	foreach ($lex1 in $lex){
		if ($line -match $lex1){
			$flag = !$flag
		}
	}
	
	if ($flag){
		$line = $line.Trim()
		$line = $line -replace '(\s{3,})', '|'
		if ($line -ne "") {
			$line | Out-File -filepath $aaa -Encoding utf8 -Append
		}
	}
}

(Get-Content $aaa | Select-Object -Skip 1) | Set-Content $aaa -Encoding UTF8

Write-Host "Импорт данных..." -ForegroundColor Green	
$csvRko = Import-Csv -Path $aaa -Delimiter "|" -Header "№ Д/О", "Наименование счета", "Номер счета", "Сумма комиссии"
$csvIp = @()
$csvNotIp = @()

$size = $csvRko.Length

for ($i = 0; $i -lt $size; $i++){	
	#$flag - признак ИП
	$flag = $false
	
	if ($csvRko[$i]."Номер счета" -match "^408"){
		if ($csvRko[$i]."Номер счета" -notmatch "^40821"){
			$flag = $true
		}
	}	
	
	if ($flag){
		if ($csvRko[$i]."Сумма комиссии" -ne "750"){
			$csvIp += $csvRko[$i]
		}
	} else{
		if ($csvRko[$i]."Сумма комиссии" -ne "1500"){
				$csvNotIp += $csvRko[$i]
			}
	}
}	


$csvFile = "$sql_dir\ip.csv"
if (Test-Path $csvFile){
	Remove-Item $csvFile
}
$csvIp | Export-Csv -Path $csvFile -Encoding UTF8 -UseCulture -NoTypeInformation
exportXlsx -csvName $csvFile -xlsxName $xlsxIp

$csvFile = "$sql_dir\organization.csv"
if (Test-Path $csvFile){
	Remove-Item $csvFile
}
$csvNotIp | Export-Csv -Path $csvFile -Encoding UTF8 -UseCulture -NoTypeInformation
exportXlsx -csvName $csvFile -xlsxName $xlsxNotIp