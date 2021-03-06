#каталог выполнения скрипта
$homePath = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#каталог с исходными файлами
$inPath = "$homePath\in"
#исходный файл
$inFile = "report.xlsx"

#результирующий путь для экспорта
$resultPath = "$homePath\out"
#результирующий файл экспорта
$resultFile = "result.txt"

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

Function xls_to_csv
{
	Param ($xls_url)

	Remove-Item "$in\*.csv" -force

	try
	{
		$xl = New-Object -com "Excel.Application"
		$xlCSV = 6

		$wb = $xl.workbooks.open($xls_url)
		$f_csv = [System.IO.Path]::ChangeExtension($xls_url, '.csv')

		$wb.SaveAs($f_csv, $xlCSV)
		$xl.displayalerts = $False
		$wb.Close()
		Write-Host -ForegroundColor White $f_csv
	}
	Finally
	{
		$xl.Quit()
		[System.Runtime.Interopservices.Marshal]::ReleaseComObject($xl) >> $null
	}
	return $f_csv
}

function convert_csv_utf8
{
	Param ($csvFile)

	Get-Content $csvFile | Out-File -FilePath "$csvFile.001" -Encoding UTF8

	Remove-Item "$inPath\*.csv" -force
	Get-ChildItem "$inPath\*.001" | Rename-Item -NewName { $_.name -replace '\.001', '' }
}

function global:TranslitToLAT
{
	param([string]$inString)
	$Translit_To_LAT = @{
		[char]'а' = "a"
		[char]'А' = "a"
		[char]'б' = "b"
		[char]'Б' = "b"
		[char]'в' = "v"
		[char]'В' = "v"
		[char]'г' = "g"
		[char]'Г' = "g"
		[char]'д' = "d"
		[char]'Д' = "d"
		[char]'е' = "e"
		[char]'Е' = "e"
		[char]'ё' = "e"
		[char]'Ё' = "e"
		[char]'ж' = "zh"
		[char]'Ж' = "zh"
		[char]'з' = "z"
		[char]'З' = "z"
		[char]'и' = "i"
		[char]'И' = "i"
		[char]'й' = "y"
		[char]'Й' = "y"
		[char]'к' = "k"
		[char]'К' = "k"
		[char]'л' = "l"
		[char]'Л' = "l"
		[char]'м' = "m"
		[char]'М' = "m"
		[char]'н' = "n"
		[char]'Н' = "n"
		[char]'о' = "o"
		[char]'О' = "o"
		[char]'п' = "p"
		[char]'П' = "p"
		[char]'р' = "r"
		[char]'Р' = "r"
		[char]'с' = "s"
		[char]'С' = "s"
		[char]'т' = "t"
		[char]'Т' = "t"
		[char]'у' = "u"
		[char]'У' = "u"
		[char]'ф' = "f"
		[char]'Ф' = "f"
		[char]'х' = "kh"
		[char]'Х' = "kh"
		[char]'ц' = "tc"
		[char]'Ц' = "tc"
		[char]'ч' = "ch"
		[char]'Ч' = "ch"
		[char]'ш' = "sh"
		[char]'Ш' = "sh"
		[char]'щ' = "shch"
		[char]'Щ' = "shch"
		[char]'ъ' = "" # "``"
		[char]'Ъ' = "" # "``"
		[char]'ы' = "y" # "y`"
		[char]'Ы' = "y" # "Y`"
		[char]'ь' = "" # "`"
		[char]'Ь' = "" # "`"
		[char]'э' = "e" # "e`"
		[char]'Э' = "e" # "E`"
		[char]'ю' = "yu"
		[char]'Ю' = "yu"
		[char]'я' = "ya"
		[char]'Я' = "ya"
		[char]' ' = "_"
	}
	$outChars=""
	foreach ($c in $inChars = $inString.ToCharArray())
	{
		if ($Translit_To_LAT[$c] -cne $Null )
			{
				$outChars += $Translit_To_LAT[$c]
			}
		else
			{
				$outChars += $c
			}
	}
	Write-Output $outChars
}

#ClearUI
Clear-Host
Set-Location $homePath

if (!(Test-Path "$inPath\$inFile"))
{
	Write-Host -ForegroundColor Red "Файл $inPath\$inFile не найден!"
	Read-Host "Ошибка! Для выхода нажмите Enter"
	exit
}

Write-Host -ForegroundColor Green "Обрабатываем файл $inPath\$inFile"

Write-Host -ForegroundColor Green "Преобразуем в csv..."

Remove-Item "$inPath\*.csv" -force
$csvFile = xls_to_csv("$inPath\$inFile")

convert_csv_utf8($csvFile)
Write-Host -ForegroundColor Green "Фильтруем csv..."

$contetFile = Get-Content $csvFile
$j = 0
$flag = $false
$max_line = $contetFile.count
foreach ($line in $contetFile)
{
	if ($line -Match "N п/п;ФИО;Домашний адрес")
	{
		$flag = $true
		continue;
	}

	if ($flag)
	{
		if ($line -ne "")
		{
			<#if ($line -match ";;;;"){
				continue
			}
			$line = $line -replace ";;;", ";"#>
			$array = $line.Split(';')
			for ($i=0; $i -lt $array.length; $i++) {
				$array[$i] = $array[$i].Trim()
			}
			$line = $array -join ';'
			$line | Out-File -FilePath "$csvFile.001" -Encoding UTF8 -Append
		}
	}
	Write-Progress -Activity $j -PercentComplete ($j / $max_line * 100) -Status "Фильтрация"
	$j++
}
Remove-Item "$inPath\*.csv" -force
Get-ChildItem "$inPath\*.001" | Rename-Item -NewName { $_.name -replace '\.001', '' }

Write-Host -ForegroundColor Green "Обработка данных..."

#$data = Import-Csv -Path $csvFile -Delimiter ';' -Header "N", "FIO", "Address", "Seriya", "Nomer", "Date1", "Kem", "Date2", "Mesto" | select *,FIOLat
#$data = Import-Csv -Path $csvFile -Delimiter ';' -Header "FIO", "DateOfBirth", "Mesto", "Seriya", "Nomer", "DateOfIssue", "Kem", "Address", "Nachalo"
$data = Import-Csv -Path $csvFile -Delimiter ';' -Header "N", "FIO", "Address", "Seriya", "Nomer", "DateOfIssue", "Kem", "DateOfBirth", "Mesto" | select *,FIOLat
Remove-Item "$inPath\*.csv" -force

$max = ($data|Measure-Object).count
if ($max -eq 1)
{
	$curItem = $data
	$data = @()
	$data += $curItem
}

for ($i = 0; $i -lt $max; $i++) {
	$fioArray = $data[$i].FIO.Split(' ')
	$latSurname = (TranslitToLAT $fioArray[0]).ToUpper()
	$latName = (TranslitToLAT $fioArray[1]).ToUpper()
	$data[$i].FIOLat = "$latName/$latSurname"
	$data[$i].FIO = $fioArray -join '^'
	#$data[$i].Mesto = $data[$i].Mesto -replace "0,", ""
	Write-Progress -Activity $data[$i].FIO -PercentComplete ($i / $max * 100) -Status "Обработка данных"
}

Write-Host -ForegroundColor Green "Экспорт данных в $resultPath\$resultFile"
Remove-Item "$resultPath\*.txt" -force
for ($i = 0; $i -lt $max; $i++) {
	$line = $data[$i].FIO + "^" + $data[$i].Address + "^?^" + $data[$i].Seriya + "^" + $data[$i].Nomer + "^" + $data[$i].DateOfIssue + "^" + $data[$i].Kem + "^" + $data[$i].DateOfBirth + "^" + $data[$i].Mesto + "^^?^" + $data[$i].FIOLat+ "^"
	$line | Out-File -FilePath "$resultPath\$resultFile" -Encoding OEM -Append
	Write-Progress -Activity $data[$i].FIO -PercentComplete ($i / $max * 100) -Status "Экспорт данных"
}

Write-Host "Конвертируем dos -> win" -ForegroundColor Green
./dostowin.exe "$resultPath\$resultFile" > $null