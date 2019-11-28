#исходный каталог
$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
[string]$inFile = "$curDir\in\ext_op1.out"
[string]$tmpPath = "$curDir\tmp"
[string]$outPath = "$curDir\out"
$curDate = Get-Date -Format "ddMMyyyy"
[string]$outFile = "$curDir\out\sumReport" + $curDate + ".xlsx"
[string]$dostowin = "$curDir\lib\dostowin.exe"

. $curDir/lib/libs.ps1

Set-Location $curDir

#ClearUI
Clear-Host
$Error.Clear()
[System.Console]::OutputEncoding = [System.Console]::InputEncoding = [System.Text.Encoding]::UTF8

if (-not (get-command Import-Excel -ErrorAction SilentlyContinue)) {
    Write-Host "Модуль Import-Excel не установлен. Дальнейшая работа невозможна! Выполните установку отсюда https://github.com/dfinke/ImportExcel" -ForegroundColor Red
    exit
}

createDir(@($tmpPath, $outPath))
Remove-Item "$tmpPath\*.*" -recurse | Where { ! $_.PSIsContainer }
testFiles(@($inFile, $dostowin))

Remove-Item $outFile -ErrorAction Ignore

Copy-Item $inFile $tmpPath

Write-Host "Конвертируем dos -> win" -ForegroundColor Green
$fileName = Split-Path $inFile -leaf
./lib/dostowin.exe "$tmpPath\$fileName" > $null

$fileContent = Get-Content "$tmpPath\$fileName"
#$fileContent = Get-Content "$tmpPath\$fileName" | Select-Object -First 31

[string]$regPattern = '¦[0-9, " ", "."]{8}¦[0-9, " "]{2}¦[0-9, " "]{8}¦[0-9, " "]{9}¦[0-9, " "]{20}¦[0-9, " "]{20}¦[0-9, " ", "."]{16}¦[0-9, " ", "."]{16}¦'

[int]$maxLine = $fileContent.count
[int]$j = 0
$csvResult = @()

foreach ($curLine in $fileContent) {
    if ($curLine -match $regPattern) {
        [array]$list = @()
        $list = $curLine.Split("¦")

        $obj = New-Object PsObject
        $obj | Add-Member -MemberType NoteProperty -Name "Дата" -Value $list[1].Trim()
        $obj | Add-Member -MemberType NoteProperty -Name "КБ" -Value $list[4].Trim()
        $obj | Add-Member -MemberType NoteProperty -Name "ВнешCчет" -Value $list[5].Trim()
        $obj | Add-Member -MemberType NoteProperty -Name "Счет" -Value $list[6].Trim()
        [double]$sum = $list[7].Trim()
        $obj | Add-Member -MemberType NoteProperty -Name "Дебет" -Value $sum

        if ($sum -gt 0) {
            $csvResult += $obj
        }
    }

    Write-Progress -Activity $j -PercentComplete ($j / $maxLine * 100) -Status "Загрузка данных"
    $j++
}

$summer = @{ }
foreach ($elem in $csvResult) {
    $summer[$elem.Счет] += $elem.Дебет
}
$summer = $summer.GetEnumerator() | Sort-Object -Property name

Write-Host "Экспорт в Excel" -ForegroundColor Green
$csvTable = @()

foreach ($obj in $summer.GetEnumerator()) {
    $acc = $obj.Name + '`'

    $item = New-Object PsObject
    $item | Add-Member -MemberType NoteProperty -Name "Счет" -Value $acc
    $item | Add-Member -MemberType NoteProperty -Name "Дебет" -Value $obj.Value

    $csvTable += $item
}

foreach ($elem in $csvResult) {
    $elem.Счет += '`'
    if ($elem.ВнешCчет -ne ''){
        $elem.ВнешCчет += '`'
    }
}

$csvTable | Export-Excel -Path $outFile -AutoSize -WorkSheetname "Сводная" -TableName Pivot
$csvResult | Export-Excel -Path $outFile -AutoSize -WorkSheetname "Детальная" -TableName Detailed

$excel = Open-ExcelPackage $outFile
$sheet1 = $excel.Workbook.Worksheets["Сводная"]
Set-Format -Address $sheet1.Cells["B:B"] -NumberFormat '#,##0.00' -AutoFit
Close-ExcelPackage $excel

if (Test-Path $outFile){
    Write-Host "Файл $outFile создан" -ForegroundColor Green
}