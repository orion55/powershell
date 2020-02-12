#Программа для разбиения Excel-файла на другие с фильтрации
#(c) Гребенёв О.Е. 7.02.2020

[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
Set-Location $curDir
[string]$lib = "$curDir\lib"

. $curDir/variables.ps1
. $lib/libs.ps1
. $lib/libTSP.ps1

Clear-Host

if (-not (get-command Import-Excel -ErrorAction SilentlyContinue)) {
    Write-Host "Модуль Import-Excel не установлен. Дальнейшая работа невозможна! Выполните установку отсюда https://github.com/dfinke/ImportExcel" -ForegroundColor Red
    exit
}

createDir(@($tmpPath, $outPath))
Remove-Item "$tmpPath\*.*" -recurse | Where-Object { ! $_.PSIsContainer }
testFiles(@($dostowin))

$xlsFile = getFileXLS -folder $inPath
Write-Host -ForegroundColor Green "Импорт данных из файла $($xlsFile.FullName)"
$csvFile = xlsToCsv -xlsUrl $xlsFile -tmp $tmpPath
convertCsvUtf8 -csvFile $csvFile -tmp $tmpPath

$nameSplit = $xlsFile.BaseName -split "_"
$name = ''
$curDate = Get-Date -Format "ddMMyyyy"
if ($nameSplit.Length -eq 1) {
    $name = $curDate
}
else {
    $name = $nameSplit[1]
}

$data = Import-Csv -Path $csvFile -Delimiter ';' -Header "OFFICE", "TARGET_NUMBER", "SOURCE_NUMBER", "AUTH_CODE", "TRANS_DETAILS", "TRANS_DATE", "TRANS_AMOUNT", "FEE_TSP", "FEE_PETROCOM", "FEE_OUR", "POSTING_DATE", "ВЫПУЩЕНА", "СЧЕТ_ВОЗВРАТА"

if ($debug) {
    [int]$maxLine = 100
    Remove-Item "$outPath\*.xlsx" -Force
}
else {
    [int]$maxLine = $data.count
}

$result = @{ }
$stat = @{ }

foreach ($key in $org.keys) {
    $stat[$key] = @{
        'Count'        = 0
        'Sum'          = 0
        'Commission'   = 0
        'Compensation' = 0
    }
}

for ($i = 0; $i -lt $maxLine; $i++) {
    $details = $data[$i].TRANS_DETAILS
    if ($org.ContainsKey($details)) {
        $obj = $data[$i]
        $obj.СЧЕТ_ВОЗВРАТА = $obj.СЧЕТ_ВОЗВРАТА + '`'
        $result[$details] += @($obj)

        $stat[$details].Count += 1
        $stat[$details].Sum += $obj.TRANS_AMOUNT.Replace(',', '.')
        $stat[$details].Commission += $obj.FEE_TSP.Replace(',', '.')
    }
    Write-Progress -Activity $data[$i].СЧЕТ_ВОЗВРАТА -PercentComplete ($i / $maxLine * 100) -Status $details
}
foreach ($key in $org.keys) {
    $stat[$key].Compensation = $stat[$key].Sum - $stat[$key].Commission
}

$item = New-Object PsObject
$item | Add-Member -MemberType NoteProperty -Name "Количество" -Value 0
$item | Add-Member -MemberType NoteProperty -Name "Сумма платежей" -Value 0
$item | Add-Member -MemberType NoteProperty -Name "Комиссия" -Value 0
$item | Add-Member -MemberType NoteProperty -Name "Сумма возмещения" -Value 0

foreach ($key in $org.keys) {
    [string]$outFile = "$curDir\out\" + $org[$key] + " " + $name + ".xlsx"
    $result[$key] | Export-Excel -Path $outFile -AutoSize -WorkSheetname "Общая" -TableName Pivot -TableStyle Medium2

    $item.Количество = $stat[$key].Count
    $item.'Сумма платежей' = $stat[$key].Sum
    $item.Комиссия = $stat[$key].Commission
    $item.'Сумма возмещения' = $stat[$key].Compensation
    $item  | Export-Excel -Path $outFile -AutoSize -WorkSheetname "Итого" -TableName Pivot2 -TableStyle Medium2 -Append -Numberformat '#,##0.00'

    formatExcel -file $outFile

    Write-Host "Файл $outFile создан" -ForegroundColor Cyan
}

