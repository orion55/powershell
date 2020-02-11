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
        $obj = $data[$i] | Select-Object TRANS_DETAILS, TRANS_AMOUNT, FEE_TSP
        $obj.TRANS_AMOUNT = $obj.TRANS_AMOUNT.Replace(',', '.')
        $result[$details] += @($obj)

        $stat[$details].Count += 1
        $stat[$details].Sum += [int]$obj.TRANS_AMOUNT
        $obj.TRANS_AMOUNT
        $stat[$details].Commission += [int]$obj.FEE_TSP
    }
    Write-Progress -Activity $data[$i].СЧЕТ_ВОЗВРАТА -PercentComplete ($i / $maxLine * 100) -Status $details
}
