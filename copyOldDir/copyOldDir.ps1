#перемещение каталогов с датой изменения больше несколькоих лет
[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
. $curDir/libs/lib.ps1

$inDir = "d:\disk_O\install\Drivers\Print"
$outDir = "d:\old\disk_O\install\Drivers\Print"
$numYear = 3

Set-Location $curDir

ClearUI

testDir(@($inDir))
#createDir(@($outDir))

$fileList = Get-ChildItem -Path $inDir -Directory | Where-object {$_.lastwritetime -le (get-date).AddYears(-$numYear)}
#$fileList = Get-ChildItem -Path $inDir -Directory

foreach ($file in $fileList){    
    Move-Item -Path $file.FullName -Destination $outDir
    Write-Host -ForegroundColor Green $file
}