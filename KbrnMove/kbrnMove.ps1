[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

$inDir = "$curDir\test\in"
$outDir = "$curDir\test\out"


Set-Location $curDir

. $curDir/libs/lib.ps1
. $curDir/libs/PSMultiLog.ps1

ClearUI

testDir(@($inDir, $outDir))

$logDir = "$curDir\log"
createDir($logDir)

$dt = Get-Date -Format "dd-MM-yyyy"
$logName = $logDir + "\" + $dt + "_LOG.log"

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

$inXml = Get-ChildItem -Path $inDir "*" -File
$count = ($inXml | Measure-Object).count
if ($count -eq 0){
    Write-Log -EntryType Error -Message "Не найдены файлы в $inDir"
    Stop-FileLog
    Stop-HostLog
    exit
} else {
    try {
        $msg = $inXml | Move-Item -Destination $outDir -ErrorAction Stop -Verbose -Force *>&1    
        Write-Log -EntryType Information -Message ($msg | Out-String)  
        Write-Log -EntryType Information -Message "Файл(ы) перемещен(ы) в $outDir"
    }
    catch {    
        Write-Log -EntryType Error -Message "Ошибка перемещения файла(ов) в $outDir"
        exit
    }
}

Stop-FileLog
Stop-HostLog