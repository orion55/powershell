#исходный каталог
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
$csvIn = "$dir1\import_export_xls_product_tools.csv"
$csvResultFile = "$dir1\result.csv"
$imagePrefix = "catalog/pet/"
$imageUrlFile = "$dir1\imageUrl.txt"
$maxAmount = 15

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

function ImageUrl($url) {
    return $imagePrefix + $url.Substring($url.LastIndexOf("/") + 1)
}

Set-Location $dir1

ClearUI

Test_files(@($csvIn))

if ((Test-Path $csvResultFile)){
    Remove-Item $csvResultFile -Force
}

if ((Test-Path $imageUrlFile)){
    Remove-Item $imageUrlFile -Force
}


$xmlFile = Get-ChildItem "$dir1\*.xml"
if (($xmlFile|Measure-Object).count -eq 0){
	exit
}

[xml]$xml = Get-Content $xmlFile
$categories = $xml.yml_catalog.shop.categories.category

$hash = [ordered]@{}
$hashAmount = [ordered]@{}
for ($i=0; $i -le $categories.Count - 1; $i++) {
    $hash.add([string]$categories[$i].id, [string]$categories[$i].'#text')
    $hashAmount.add([string]$categories[$i].id, 0)
}

$etalon = import-csv $csvIn -Delimiter ';'
foreach( $property in $etalon.psobject.properties.name )
{
    $etalon.$property = ''
}

$csvResult = @()
$offers = $xml.yml_catalog.shop.offers.offer
$count = $offers.Count

for ($i=0; $i -le $count - 1; $i++) {    
    Write-Progress -Activity $offers[$i].name -PercentComplete ($i / $count * 100) -Status "Экспорт csv"

    $catId = $hashAmount[$offers[$i].categoryId]
    if ($maxAmount -ne 0 -and $catId -ge $maxAmount){
        continue
    }
    $hashAmount[$offers[$i].categoryId]++
    $obj."Cat. 1" = $hash[$offers[$i].categoryId]
    
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
    
    $obj."Weight" = $offers[$i].weight 
    $obj."Status" = 1
    
    $param = $offers[$i].param
    $paramHash = @{}
    foreach( $property in $param)
    {
        $paramHash[$property.name] = $property.'#text'
    }
    
    $length = $paramHash."Глубина упаковки"
    if ($length -ne $null){
        $obj."Length" = $length
    }
    $width = $paramHash."Ширина упаковки"
    if ($width -ne $null){
        $obj."Width" = $width
    }
    $height = $paramHash."Высота упаковки"
    if ($height -ne $null){
        $obj."Height" = $height
    }

    $pictures = $offers[$i].picture
    if (($pictures|Measure-Object).count -eq 1){
        $obj."Main image" = ImageUrl($pictures)
        $pictures | Out-File -FilePath $imageUrlFile -Append -Encoding utf8
    } else {
        $obj."Main image" = ImageUrl($pictures[0])
        $pictures[0] | Out-File -FilePath $imageUrlFile -Append -Encoding utf8
        
        if ($pictures[1] -ne $null){
            $obj."Image 2" = ImageUrl($pictures[1])
            $pictures[1] | Out-File -FilePath $imageUrlFile -Append -Encoding utf8
        }
        
        if ($pictures[2] -ne $null){
            $obj."Image 3" = ImageUrl($pictures[2])
            $pictures[2] | Out-File -FilePath $imageUrlFile -Append -Encoding utf8
        }
    }    
    
    $csvResult += $obj    
}

$csvResult | Export-Csv -Path $csvResultFile -Encoding UTF8 -UseCulture -NoTypeInformation
Write-Host -ForegroundColor Green "Ok!"