#каталог выполнения скрипта
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#каталог с исходными файлами
$in_dir = "$dir1\in"
#исходный файл
$file1 = "tumen.out"

#результирующий путь для экспорта
$result_path = "c:\PROVODKI\IMPORT"

#результирующий файл для юридических лиц
$result_Company = "salary.xml"
#номер счета для юридических лиц
$account_Company = "70601810700822710201"
#сумма комиссии для юридических лиц
$price_Company = "950"

#результирующий файл для индивидуальных предпринимателей
$result_IP = "salary_ip.xml"
#номер счета для индивидуальных предпринимателей
$account_IP = "70601810600822710301"
#сумма комиссии для индивидуальных предпринимателей
$price_IP = "550"

$head_xml = "$dir1\xml\header.xml"
$foot_xml = "$dir1\xml\footer.xml"

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

function generateXML($list, $account, $fname, $price){
	
	$filename = "$dir1\$fname"
	Write-Host "Создаём результирующий файл $filename" -ForegroundColor Green
	$max_line = $list.count
	$max_line++	
	
	$content = (Get-Content $head_xml) -replace '###RowCount###', $max_line 	
	$content = $content -replace '###AccountNumber###', $account 	
	$content | Out-File -FilePath $filename -Encoding UTF8
	
	$i = 1
	foreach ($cur in $list){
		"<Row ss:Height=`"15`">" | Out-File $filename -Encoding UTF8 -Append		
		"<Cell><Data ss:Type=`"Number`">$i</Data></Cell>" | Out-File $filename -Encoding UTF8 -Append
		$st1 = $cur[0].trim()
		"<Cell ss:StyleID=`"s65`"><Data ss:Type=`"String`">$st1</Data></Cell>" | Out-File $filename -Encoding UTF8 -Append
		$st1 = $cur[1].trim()
		"<Cell ss:StyleID=`"s65`"><Data ss:Type=`"String`">$st1</Data></Cell>" | Out-File $filename -Encoding UTF8 -Append
		"<Cell><Data ss:Type=`"Number`">$price</Data></Cell>" | Out-File $filename -Encoding UTF8 -Append
		"</Row>" | Out-File $filename -Encoding UTF8 -Append
		$i++
	}
	
	Get-Content $foot_xml | Out-File $filename -Encoding UTF8 -Append
	
	$xlsxName = $fname.Split('.')[0]
	$xlsxFilename = "$result_path\$xlsxName.xls"
	if (Test-Path $xlsxFilename){
		Remove-Item $xlsxFilename
	}
	Write-Host "Экспортируем результат в файл $xlsxFilename" -ForegroundColor Yellow
	$excelObj = New-Object -ComObject Excel.Application
	$excelObj.Visible = $false
	$workBook = $excelObj.Workbooks.Open($filename)	
	$workbook.SaveAs($xlsxFilename, 56)
	$workbook.Close($false)
	$excelObj.Quit()
	[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excelObj) > $null	
	Remove-Variable excelObj	
}

ClearUI
Set-Location $dir1

if (!(Test-Path "$in_dir\$file1"))
{
	Write-Error "Файл $in_dir\$file1 не найден!"
	Read-Host "Ошибка! Для выхода нажмите Enter"
	exit
}

Write-Host "Конвертируем dos -> win" -ForegroundColor Green
if (Test-Path "$dir1\$file1")
{
	Remove-Item $dir1\$file1
}
Copy-Item $in_dir\$file1 $dir1\$file1
./dostowin.exe $dir1\$file1 > $null

Write-Host "Считываем данные из файла" -ForegroundColor Green
$file2 = Get-Content "$dir1\$file1"
$reg1 = '¦[0-9, " "]{3}¦[0-9]{20}¦.{56}¦[0-9, ".", " "]{15}¦[0-9, ".", " "]{15}¦[0-9, ".", " "]{15}¦[0-9, ".", " "]{15}¦[0-9, ".", " "]{15}¦'
$company_list = @()
$list_ip = @()
foreach ($line1 in $file2)
{	
	if ($line1 -match $reg1)
	{
		$list = @()
		$list = $line1.Split("¦")
		if ($list[2].Substring(0, 3) -eq '407'){
			$company_list += (,($list[3], $list[2]))
		}
		if ($list[2].Substring(0, 3) -eq '408'){
			$list_ip += (,($list[3], $list[2]))
		}			
	}
}

generateXML $company_list $account_Company $result_Company $price_Company
generateXML $list_ip $account_IP $result_IP $price_IP
