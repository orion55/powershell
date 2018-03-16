#каталог выполнения скрипта
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#путь до драйвера базы данных
$scriptDir = "$dir1\sqlitex64"

$database = "$dir1\db\data1.db"
$connStr = "Data Source = $database"
Add-Type -Path "$scriptDir\System.Data.SQLite.dll"
$in = "$dir1\in"
$out = "$dir1\out"
$head_xml = "$dir1\db\head.xml"
$tbl_xml = "$dir1\db\tbl.xml"
$tbl_end = "$dir1\db\tbl_end.xml"
$ColCount = 14 #количество колонок

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
		Write-Host $f_csv -ForegroundColor Blue
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
	Param ($urls)
	
	foreach ($f1 in $urls)
	{
		Get-Content $f1 | Out-File -FilePath "$f1.001" -Encoding UTF8
	}
	
	Remove-Item "$dir1\xls\*.csv" -force
	Get-ChildItem "$dir1\xls\*.001" | Rename-Item -NewName { $_.name -replace '\.001', '' }
}

Function querySQLite
{
	param ([string]$query)
	
	$datatSet = New-Object System.Data.DataSet
	
	$conn = New-Object System.Data.SQLite.SQLiteConnection($connStr)
	$conn.Open()
	
	$dataAdapter = New-Object System.Data.SQLite.SQLiteDataAdapter($query, $conn)
	[void]$dataAdapter.Fill($datatSet)
	
	$conn.close()
	return $datatSet.Tables[0].Rows
	
}

Function writeSQLite
{
	param ([string]$query)
	
	$conn = New-Object System.Data.SQLite.SQLiteConnection($connStr)
	$conn.Open()
	
	$command = $conn.CreateCommand()
	$command.CommandText = $query
	$RowsInserted = $command.ExecuteNonQuery()
	$command.Dispose()
	$conn.close()
}

function convert_csv_utf8
{
	Param ($url)
	
	Get-Content $url | Out-File -FilePath "$url.001" -Encoding UTF8
	
	Remove-Item "$in\*.csv" -force
	Get-ChildItem "$in\*.001" | Rename-Item -NewName { $_.name -replace '\.001', '' }
}

Function Replace_minus
{
	param ($csv1)
	
	$max_csv = $csv1.count
	for ($i = 0; $i -lt $max_csv; $i++)
	{
		$csv1[$i]."Рублевый эквивалент" = $csv1[$i]."Рублевый эквивалент" -replace "-", ""
		$csv1[$i]."Рублевый эквивалент" = $csv1[$i]."Рублевый эквивалент" -replace "`,", "."
		$csv1[$i]."НЕРАЗРЕШЕННЫЙ_ОВЕРДРАФТ" = $csv1[$i]."НЕРАЗРЕШЕННЫЙ_ОВЕРДРАФТ" -replace "-", ""
		$csv1[$i]."НЕРАЗРЕШЕННЫЙ_ОВЕРДРАФТ" = $csv1[$i]."НЕРАЗРЕШЕННЫЙ_ОВЕРДРАФТ" -replace "`,", "."
		$csv1[$i]."BALANS_TO_DATE" = $csv1[$i]."BALANS_TO_DATE" -replace "`,", "."
		$csv1[$i]."Неиспользованный_лимит" = $csv1[$i]."Неиспользованный_лимит" -replace "`,", "."
	}
	
	return $csv1
}

Function Empty_Tables
{
	$writeQuery = "DELETE FROM fee0002 WHERE 1"
	writeSQLite($writeQuery)
	$writeQuery = "DELETE FROM dollars WHERE 1"
	writeSQLite($writeQuery)
	$writeQuery = "DELETE FROM euro WHERE 1"
	writeSQLite($writeQuery)
	$writeQuery = "DELETE FROM corp WHERE 1"
	writeSQLite($writeQuery)
}

Function Import_fee0002
{
	param ($csv1)
	
	$conn = New-Object System.Data.SQLite.SQLiteConnection($connStr)
	$conn.Open()
	$trans = $conn.BeginTransaction()
	
	$command = $conn.CreateCommand()
	$command.CommandText = "INSERT INTO fee0002 (fi, client, contr_num, acc_num, curr, pos, data_zak, bal_to_date, rub_ekvival, day_komis, limit1, ne_limit, ne_overdraft) VALUES (@fi, @client, @contr_num, @acc_num, @curr, @pos, @data_zak, @bal_to_date, @rub_ekvival, @day_komis, @limit1, @ne_limit, @ne_overdraft)"
	
	#$command.CommandText = "INSERT INTO fee0002 (fi, client) VALUES (@fi, @client)"
	
	$max_csv = $csv1.count
	for ($i = 0; $i -lt $max_csv; $i++)
	{
		$t_csv = $csv1[$i]
		$command.Parameters.AddWithValue("@fi", $t_csv."FI") | out-null
		$command.Parameters.AddWithValue("@client", $t_csv."CLIENT") | out-null
		$command.Parameters.AddWithValue("@contr_num", $t_csv."CONTRACT_NUMBER") | out-null
		$command.Parameters.AddWithValue("@acc_num", $t_csv."ACCOUNT_NUMBER") | out-null
		$command.Parameters.AddWithValue("@curr", $t_csv."CURR") | out-null
		$command.Parameters.AddWithValue("@pos", $t_csv."POS") | out-null
		$command.Parameters.AddWithValue("@data_zak", $t_csv."Дата закрытия") | out-null
		$command.Parameters.AddWithValue("@bal_to_date", $t_csv."BALANS_TO_DATE") | out-null
		$command.Parameters.AddWithValue("@rub_ekvival", $t_csv."Рублевый эквивалент") | out-null
		$command.Parameters.AddWithValue("@day_komis", $t_csv."ДНЕЙ_КОМИСССИЯ_НАЧ") | out-null
		
		$temp1 = $t_csv."Лимит"
		if ($temp1 -eq "")
		{
			$temp1 = $null
		}
		$command.Parameters.AddWithValue("@limit1", $temp1) | out-null
		
		$temp1 = $t_csv."Неиспользованный_лимит"
		if ($temp1 -eq "")
		{
			$temp1 = $null
		}
		$command.Parameters.AddWithValue("@ne_limit", $temp1) | out-null
		$command.Parameters.AddWithValue("@ne_overdraft", $t_csv."НЕРАЗРЕШЕННЫЙ_ОВЕРДРАФТ") | out-null
		$RowsInserted = $command.ExecuteNonQuery()
		
		$activ = $t_csv."CLIENT"
		if ($activ -eq "")
		{
			$activ = "Null"
		}
		Write-Progress -Activity $activ -PercentComplete ($i / $max_csv * 100) -Status "Импорт"
	}
	
	$trans.Commit()
	$command.Dispose()
	$conn.close()
}

Function Export_data
{
	param ($dat1,
		[string]$st1,
		[decimal]$sm1)
	
	$max = $dat1.Count;
	$max_inc = $max + 1
	$max_inc_inc = $max_inc + 1
	
	$st2 = -join ("R", $max_inc, "C", $ColCount)
	
	"<Worksheet ss:Name=`"$st1`">" | Out-File $xml_name -Encoding UTF8 -Append
	"<Names>" | Out-File $xml_name -Encoding UTF8 -Append
	"<NamedRange ss:Name=`"_FilterDatabase`" ss:RefersTo=`"=$st1!R1C1:$st2`" ss:Hidden=`"1`"/>" | Out-File $xml_name -Encoding UTF8 -Append
	"</Names>" | Out-File $xml_name -Encoding UTF8 -Append
	"<Table ss:ExpandedColumnCount=`"$ColCount`" ss:ExpandedRowCount=`"$max_inc_inc`" x:FullColumns=`"1`" x:FullRows=`"1`">" | Out-File $xml_name -Encoding UTF8 -Append
	
	Get-Content $tbl_xml | Out-File $xml_name -Encoding UTF8 -Append
	
	$max_csv = $dat1.count
	$i = 0
	foreach ($d1 in $dat1)
	{
		"<Row>" | Out-File $xml_name -Encoding UTF8 -Append
		$st3 = [string]$d1.fi
		"<Cell><Data ss:Type=`"String`">$st3</Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		
		$st3 = [string]$d1.client
		if ($st3 -ne "")
		{
			"<Cell><Data ss:Type=`"String`">$st3</Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		}
		else
		{
			"<Cell><Data ss:Type=`"String`"></Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		}
		$st3 = [string]$d1.contr_num
		"<Cell><Data ss:Type=`"String`">$st3</Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		$st3 = [string]$d1.acc_num
		"<Cell><Data ss:Type=`"String`">$st3</Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		$st3 = [string]$d1.curr
		"<Cell><Data ss:Type=`"String`">$st3</Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		$st3 = [string]$d1.pos
		"<Cell><Data ss:Type=`"String`">$st3</Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		$st3 = [string]$d1.data_zak
		"<Cell><Data ss:Type=`"String`">$st3</Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		$num = [Double]$d1.bal_to_date
		"<Cell><Data ss:Type=`"Number`">$num</Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		$num = [Double]$d1.rub_ekvival
		"<Cell><Data ss:Type=`"Number`">$num</Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		$num = [Double]$d1.day_komis
		"<Cell><Data ss:Type=`"Number`">$num</Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		
		if ($d1.limit1 -eq [System.DBNull]::Value)
		{
			"<Cell><Data ss:Type=`"String`"></Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		}
		else
		{
			$num = [Double]$d1.limit1
			"<Cell><Data ss:Type=`"Number`">$num</Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		}
		if ($d1.ne_limit -eq [System.DBNull]::Value)
		{
			"<Cell><Data ss:Type=`"String`"></Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		}
		else
		{
			$num = [Double]$d1.ne_limit
			"<Cell><Data ss:Type=`"Number`">$num</Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		}
		
		$num = [Double]$d1.ne_overdraft
		"<Cell><Data ss:Type=`"Number`">$num</Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		$num = [Double]$d1.rvp
		"<Cell><Data ss:Type=`"Number`">$num</Data><NamedCell ss:Name=`"_FilterDatabase`"/></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
		"</Row>" | Out-File $xml_name -Encoding UTF8 -Append
		
		$st3 = [string]$d1.client
		if ($st3 -eq "")
		{
			$st3 = " "
		}
		Write-Progress -Activity $st3 -Status $st1 -PercentComplete ($i / $max_csv * 100)
		$i++
	}
	"<Row ss:StyleID=`"s61`">" | Out-File $xml_name -Encoding UTF8 -Append
	"<Cell ss:StyleID=`"s81`"><Data ss:Type=`"String`">Итого</Data></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
	
	for ($i = 0; $i -lt $ColCount - 2; $i++)
	{
		"<Cell ss:StyleID=`"s81`"/>" | Out-File $xml_name -Encoding UTF8 -Append
	}
	"<Cell ss:StyleID=`"s82`"><Data ss:Type=`"Number`">$sm1</Data></Cell>" | Out-File $xml_name -Encoding UTF8 -Append
	"</Row>" | Out-File $xml_name -Encoding UTF8 -Append
	Get-Content $tbl_end | Out-File $xml_name -Encoding UTF8 -Append
}


Clear-Host
Set-Location $dir1

if (!(Test-Path $head_xml))
{
	Write-Host -ForegroundColor Red "Не найден файл $head_xml"
	exit
}

if (!(Test-Path $tbl_xml))
{
	Write-Host -ForegroundColor Red "Не найден файл $tbl_xml"
	exit
}

if (!(Test-Path $tbl_end))
{
	Write-Host -ForegroundColor Red "Не найден файл $tbl_end"
	exit
}

$last_xls = Get-ChildItem "$in\fee0002_*.xls" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$date_name = $last_xls.name.Substring(8, 8)

$inp_date = Read-Host -Prompt "Введите дату для обработки или нажмите Enter для [$date_name]"
$dir2 = "$in\fee0002_$inp_date.XLS"

if ($inp_date -ne "")
{	
	if (!(Test-Path($dir2)))
	{
		Write-Host -ForegroundColor Red "Не найден файл $dir2"
		exit
	}
	$last_xls = Get-ChildItem $dir2
}

Write-Host -ForegroundColor Blue "Обрабатываем файл $last_xls"

Write-Host -ForegroundColor Blue "Преобразуем в csv..."
$last_csv = xls_to_csv("$last_xls")

convert_csv_utf8($last_csv)
$fee_csv = Import-Csv -Path $last_csv -Delimiter ";"
Write-Host -ForegroundColor Blue "Заменяем `"минуса`"..."
$fee_csv = Replace_minus($fee_csv)

Empty_Tables

Write-Host -ForegroundColor Green "Импортируем в базу данных..."
Import_fee0002($fee_csv)
Remove-Item "$in\*.csv" -force

Write-Host -ForegroundColor Green "Обработка данных..."

$writeQuery = "INSERT INTO dollars (fi, client, contr_num, acc_num, curr, pos, data_zak, bal_to_date, rub_ekvival, day_komis, limit1, ne_limit, ne_overdraft) SELECT fi, client, contr_num, acc_num, curr, pos, data_zak, bal_to_date, rub_ekvival, day_komis, limit1, ne_limit, ne_overdraft FROM fee0002 where curr=840 order by client"
writeSQLite($writeQuery)
$writeQuery = "DELETE FROM fee0002 where curr=840"
writeSQLite($writeQuery)

$writeQuery = "INSERT INTO euro (fi, client, contr_num, acc_num, curr, pos, data_zak, bal_to_date, rub_ekvival, day_komis, limit1, ne_limit, ne_overdraft) SELECT fi, client, contr_num, acc_num, curr, pos, data_zak, bal_to_date, rub_ekvival, day_komis, limit1, ne_limit, ne_overdraft FROM fee0002 where curr=978 order by client"
writeSQLite($writeQuery)
$writeQuery = "DELETE FROM fee0002 where curr=978"
writeSQLite($writeQuery)

$writeQuery = "update dollars set rvp = rub_ekvival where day_komis > 30"
writeSQLite($writeQuery)

$writeQuery = "update dollars set rvp = rub_ekvival*0.01 where day_komis >= 1 and day_komis <= 30"
writeSQLite($writeQuery)

$writeQuery = "update euro set rvp = rub_ekvival where day_komis > 30"
writeSQLite($writeQuery)

$writeQuery = "update euro set rvp = rub_ekvival*0.01 where day_komis >= 1 and day_komis <= 30"
writeSQLite($writeQuery)

$writeQuery = "INSERT INTO corp (fi, client, contr_num, acc_num, curr, pos, data_zak, bal_to_date, rub_ekvival, day_komis, limit1, ne_limit, ne_overdraft) 
SELECT fi, client, contr_num, acc_num, curr, pos, data_zak, bal_to_date, rub_ekvival, day_komis, limit1, ne_limit, ne_overdraft FROM fee0002 WHERE contr_num NOT LIKE '40817%' AND contr_num NOT LIKE '40820%'"
writeSQLite($writeQuery)

$writeQuery = "DELETE FROM fee0002 WHERE contr_num NOT LIKE '40817%' AND contr_num NOT LIKE '40820%'"
writeSQLite($writeQuery)

$writeQuery = "update corp set rvp = rub_ekvival where day_komis > 30"
writeSQLite($writeQuery)

$writeQuery = "update corp set rvp = rub_ekvival*0.01 where day_komis >= 1 and day_komis <= 30"
writeSQLite($writeQuery)

$writeQuery = "update fee0002 set rvp = rub_ekvival where ne_overdraft > 0"
writeSQLite($writeQuery)

$writeQuery = "update fee0002 set rvp = rub_ekvival where limit1 > 0 and pos = `"ПОС1`" and limit1 is not null and day_komis > 30"
writeSQLite($writeQuery)

$writeQuery = "update fee0002 set rvp = rub_ekvival*0.01 where limit1 > 0 and pos = `"ПОС1`" and limit1 is not null and day_komis <= 30"
writeSQLite($writeQuery)

$writeQuery = "update fee0002 set rvp = rub_ekvival where ne_limit > 0 and pos = `"Безнадежные`" and ne_limit is not null"
writeSQLite($writeQuery)

$writeQuery = "update fee0002 set rvp = rub_ekvival*0.01 where rvp is null and day_komis BETWEEN 1 and 30"
writeSQLite($writeQuery)

$writeQuery = "update fee0002 set rvp = rub_ekvival where rvp is null and day_komis > 30"
writeSQLite($writeQuery)

Write-Host -ForegroundColor Blue "`nРезультаты"

$readQuery = "select round(sum(rvp), 2) as sum1 from dollars"
$dollars_data1 = querySQLite($readQuery)
Write-Host -ForegroundColor Blue "Доллары:`t", $dollars_data1.sum1

$readQuery = "select round(sum(rvp), 2) as sum1 from euro"
$euro_data1 = querySQLite($readQuery)
Write-Host -ForegroundColor Blue "Евро:`t", $euro_data1.sum1

$readQuery = "select round(sum(rvp), 2) as sum1 from corp"
$corp_data1 = querySQLite($readQuery)
Write-Host -ForegroundColor Blue "Корпоративный:`t", $corp_data1.sum1

$readQuery = "select round(sum(rvp), 2) as sum1 from fee0002"
$fee0002_data1 = querySQLite($readQuery)
Write-Host -ForegroundColor Blue "Основной:`t", $fee0002_data1.sum1

$dir_name = $last_xls.name.Substring(8, 8)
$dir_name = -join ($out, "\$dir_name")

If (Test-Path $dir_name)
{
	Remove-Item -Recurse -Force $dir_name
}

New-Item -ItemType directory -Path $dir_name | Out-Null
$xml_name = -join ($last_xls.name.Split('.')[0], '-final', '.xml')
$xml_name = -join ($dir_name, "\$xml_name")

If (Test-Path $xml_name)
{
	Remove-Item -Force $xml_name
}
Write-Host -ForegroundColor Blue "`nЗаписываем результаты в файл $xml_name"

Get-Content $head_xml | Out-File $xml_name -Encoding UTF8 -Append

$readQuery = "SELECT fi, client, contr_num, acc_num, curr, pos, data_zak, bal_to_date, rub_ekvival, day_komis, limit1, ne_limit, ne_overdraft, rvp FROM dollars order by day_komis"
$data1 = querySQLite($readQuery)
Export_data -dat1 $data1 -st1 "Доллары" -sm1 $dollars_data1.sum1

$readQuery = "SELECT fi, client, contr_num, acc_num, curr, pos, data_zak, bal_to_date, rub_ekvival, day_komis, limit1, ne_limit, ne_overdraft, rvp FROM euro order by day_komis"
$data1 = querySQLite($readQuery)
Export_data -dat1 $data1 -st1 "Евро" -sm1 $euro_data1.sum1

$readQuery = "SELECT fi, client, contr_num, acc_num, curr, pos, data_zak, bal_to_date, rub_ekvival, day_komis, limit1, ne_limit, ne_overdraft, rvp FROM corp order by day_komis"
$data1 = querySQLite($readQuery)
Export_data -dat1 $data1 -st1 "Корпоративный" -sm1 $corp_data1.sum1

$readQuery = "SELECT fi, client, contr_num, acc_num, curr, pos, data_zak, bal_to_date, rub_ekvival, day_komis, limit1, ne_limit, ne_overdraft, rvp FROM fee0002 order by day_komis"
$data1 = querySQLite($readQuery)
Export_data -dat1 $data1 -st1 "Основной" -sm1 $fee0002_data1.sum1

"</Workbook>" | Out-File $xml_name -Encoding UTF8 -Append

Write-Host -ForegroundColor Blue "Файл $xml_name сформирован!"