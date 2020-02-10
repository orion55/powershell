#Программа для разбиения Excel-файла на другие с фильтрации
#(c) Гребенёв О.Е. 7.02.2020

[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
Set-Location $curDir
[string]$lib = "$curDir\lib"

. $curDir/variables.ps1
. $lib/libs.ps1

Clear-Host

if (-not (get-command Import-Excel -ErrorAction SilentlyContinue)) {
    Write-Host "Модуль Import-Excel не установлен. Дальнейшая работа невозможна! Выполните установку отсюда https://github.com/dfinke/ImportExcel" -ForegroundColor Red
    exit
}

createDir(@($tmpPath, $outPath))
Remove-Item "$tmpPath\*.*" -recurse | Where-Object { ! $_.PSIsContainer }
testFiles(@($dostowin))

