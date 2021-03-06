#каталог выполнения скрипта
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#каталог пользователя
$bux = "U:\pastuhova\OUT"
#$bux = $dir1
#исходный файл
$file1 = "bmagazn.out"
#результирующий файл
$f_result = "$dir1\result.xml"
$head_xml = "$dir1\head.xml"
$foot_xml = "$dir1\footer.xml"

Clear-Host
Set-Location $dir1

Write-Host "Копируем файл $bux\$file1" -ForegroundColor Green
Copy-Item "$bux\$file1" $dir1 -Force

if (!(Test-Path "$dir1\$file1"))
{
	Write-Error "Файл $bux\$file1 не найден!"
	Read-Host "Ошибка! Для выхода нажмите Enter"
	exit
}

if (Test-Path $f_result)
{
	Remove-Item $f_result
}

if (!(Test-Path $head_xml))
{
	Write-Host -ForegroundColor Red "Не найден файл $head_xml"
	exit
}
if (!(Test-Path $foot_xml))
{
	Write-Host -ForegroundColor Red "Не найден файл $foot_xml"
	exit
}

Write-Host "Конвертируем dos -> win" -ForegroundColor Green
./dostowin.exe $dir1\$file1 > $null

$file2 = Get-Content "$dir1\$file1"

$reg1 = '¦[0-9, " "]{5}¦[0-9, "."]{8}¦[0-9]{20}¦[0-9]{20}¦[0-9, "."]{20}¦[0-9, "."]{20}¦[0-9, "."]{20}¦.{33}¦.{6}¦'

$account_not_debet = '9([0-9]){19}'
$account_debet = ('([0-9]){5}840[0-9]{12}', '([0-9]){5}978[0-9]{12}', '70608([0-9]){15}', '70606810([0-9]){5}2210101')
$account_kredit = ('70603([0-9]){15}', '20202840([0-9]){12}', '20202978([0-9]){12}')
$list_result = @()

$max_line = $file2.count
$j = 0
$flag = $false
foreach ($line1 in $file2)
{	
	if ($line1 -match $reg1)
	{
		$list = @()
		$list = $line1.Split("¦")
		#счета не попадающие в дебет
		if ($list[3] -match $account_not_debet){
			continue
		}
		#анализируем дебет счета
		foreach ($deb in $account_debet)
		{
			if ($list[3] -match $deb)
			{
				$list_result += (,($list))
				$flag = $true
				break
			}
		}
		#анализируем кредит счета
		if (!($flag)){
			foreach ($kred in $account_kredit)
			{
				if ($list[4] -match $kred)
				{
					$list_result += (,($list))
					$flag = $true				
				}
			}
		}
	}
	$flag = $false
	Write-Progress -Activity $j -PercentComplete ($j / $max_line * 100) -Status "Фильтрация"
	$j++
}
#удаляем пустые назначения платежа
$list_result1 = @()
foreach ($cur in $list_result){
	$st1 = $cur[8].trim()
	if ($st1.Length -ne 0){
		$list_result1 += (,($cur))		
	} 
}

#формирование xls - файла
$max_line = $list_result1.count
$max1 = $max_line + 1
(Get-Content $head_xml) -replace '###RowCount###', $max1 | Out-File $f_result -Encoding UTF8 -Append

$i = 0
foreach ($cur in $list_result1)
{
	"<Row>" | Out-File $f_result -Encoding UTF8 -Append
	$st1 = $cur[1].trim()
    "<Cell><Data ss:Type=`"Number`">$st1</Data></Cell>" | Out-File $f_result -Encoding UTF8 -Append
	$st1 = -join ('20', $cur[2].Substring(6, 2), '-', $cur[2].Substring(3, 2), '-', $cur[2].Substring(0, 2), 'T00:00:00.000')
    "<Cell ss:StyleID=`"s21`"><Data ss:Type=`"DateTime`">$st1</Data></Cell>" | Out-File $f_result -Encoding UTF8 -Append
	$st1 = $cur[3].trim()
    "<Cell ss:StyleID=`"s22`"><Data ss:Type=`"String`">$st1</Data></Cell>" | Out-File $f_result -Encoding UTF8 -Append
	$st1 = $cur[4].trim()
    "<Cell ss:StyleID=`"s22`"><Data ss:Type=`"String`">$st1</Data></Cell>" | Out-File $f_result -Encoding UTF8 -Append
	$st1 = $cur[5].trim()
    "<Cell><Data ss:Type=`"Number`">$st1</Data></Cell>" | Out-File $f_result -Encoding UTF8 -Append
	$st1 = $cur[6].trim()
    "<Cell><Data ss:Type=`"Number`">$st1</Data></Cell>" | Out-File $f_result -Encoding UTF8 -Append
	$st1 = $cur[7].trim()
    "<Cell><Data ss:Type=`"Number`">$st1</Data></Cell>" | Out-File $f_result -Encoding UTF8 -Append
	$st1 = $cur[8].trim()
    "<Cell ss:StyleID=`"s22`"><Data ss:Type=`"String`">$st1</Data></Cell>" | Out-File $f_result -Encoding UTF8 -Append 
	$st1 = $cur[9].trim()
	"<Cell ss:StyleID=`"s22`"><Data ss:Type=`"String`">$st1</Data></Cell>" | Out-File $f_result -Encoding UTF8 -Append 
	"</Row>" | Out-File $f_result -Encoding UTF8 -Append
	Write-Progress -Activity $i -PercentComplete ($i / $max_line * 100) -Status "Экспорт"
	$i++
}

Get-Content $foot_xml | Out-File $f_result -Encoding UTF8 -Append

Write-Host -ForegroundColor Blue "Файл $f_result сформирован!"