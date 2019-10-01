#создание пустых файлов с нужной структурой
[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
. $curDir/lib.ps1

$inDir = "\\tmn-ts-01\disk_O\install"
#$inDir = "\\192.168.1.71\Download\Mamul\Films"
$outDir = "$curDir\out"

Set-Location $curDir

ClearUI

createDir(@($outDir))
Remove-Item $outDir -Recurse -Force -ErrorAction silentlycontinue

$fileList = Get-ChildItem -Path $inDir -Directory

foreach ($file in $fileList){
    $newName = $($file.FullName).Replace($inDir, $outDir)
    
    $newDir = New-Item -ItemType directory -Path $newName  
    $newDir.LastAccessTime =  $file.LastAccessTime
    $newDir.LastWriteTime = $file.LastWriteTime
    $newDir.CreationTime = $file.CreationTime
    
    Write-Host -ForegroundColor Green $file.Name
}