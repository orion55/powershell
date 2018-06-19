#исходный каталог
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
$csvIn = "$dir1\import_export_xls_product_tools.csv"
$csvResultFile = "$dir1\result.csv"

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

function Test_files($files){	
	foreach ($f1 in $files){
		#проверка существования файлов
		if (!(Test-Path $f1)){
			Write-Host "Файл $f1 не найден!" -ForegroundColor Red
			Write-Host "Нажмите любую клавишу для продолжения" 
			Read-Host "Нажмите Enter"			
			Exit
		}
	}
}

Set-Location $dir1

ClearUI

$files_arr = @($csvIn)
Test_files($files_arr)

$csv = import-csv $csvIn -Delimiter ';'

$xmlFile = Get-ChildItem "$dir1\*.xml"
$count = ($xmlFile|Measure-Object).count

if ($count -eq 0){
	exit
}

[xml]$xml = Get-Content $xmlFile
$categories = $xml.yml_catalog.shop.categories.category

$hash = [ordered]@{}
for ($i=0; $i -le $categories.Count - 1; $i++) {
    $hash.add([string]$categories[$i].id, [string]$categories[$i].'#text')
}

$etalon = $csv.psobject.copy()
foreach( $property in $etalon.psobject.properties.name )
{
    $etalon.$property = ''
}

$csvResult = @()
$offers = $xml.yml_catalog.shop.offers.offer
for ($i=0; $i -le $offers.Count - 1; $i++) {
    $obj = $etalon.psobject.copy()     
    if ($offers[$i].barcode -ne $null){
        $obj."Model" = $offers[$i].barcode
    } else {
        $obj."Model" = $i
    }
    $obj."Name" = $offers[$i].name
    $obj."Description" = $offers[$i].description
    $obj."Price" = $offers[$i].price
    $obj."Quantity" = 10
    $obj."Manufacturer" = $offers[$i].vendor
    $obj."Cat. 1" = $hash[$offers[$i].categoryId]
    $obj."Weight" = $offers[$i].weight 
    $obj."Status" = 1
    $csvResult += $obj
}

$csvResult | Export-Csv -Path $csvResultFile -Encoding UTF8 -UseCulture -NoTypeInformation
Write-Host -ForegroundColor Green "Ok!"