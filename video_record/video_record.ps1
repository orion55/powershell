#создание пустых файлов с нужной структурой
[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
. $curDir/lib.ps1

#$inDir = "G:\Films"
$inDir = "$curDir\RecordFile"
$ageArchive = 30

Set-Location $curDir

ClearUI

$dirList = Get-ChildItem -Path $inDir -Directory

$dirCount = ($dirList | Measure-Object).count

if ($dirCount -gt $ageArchive){
    $diff = $dirCount - $ageArchive
    $msg = $dirList | Sort-Object $_.BaseName | Select-Object -First $diff | Remove-Item -Recurse -Verbose -Force *>&1
    (Get-Date).ToString('dd-MM-yyyy HH:mm:ss') | Out-File $curDir\log.txt -Append
    $msg | Out-String | Out-File $curDir\log.txt -Append
}
