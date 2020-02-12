$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
$debug = $false

[string]$inPath = "$curDir\in"
[string]$tmpPath = "$curDir\tmp"
[string]$outPath = "$curDir\out"

[string]$dostowin = "$curDir\lib\dostowin.exe"

$org = @{
    'AO ERIC YANAO' = 'АО ЕРИЦ ЯНАО'
    'OAO TRIC'      = 'ОАО ТРИЦ'
    'LC.YRITZ'      = 'ООО ЮРИЦ'
    'OOO NESKO'     = 'ООО НЭСКО'
}