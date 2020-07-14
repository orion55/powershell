#Программа синхронизации файлов Кворума и копирование их по папкам
#(c) Гребенёв О.Е. 14.07.2020

[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
Set-Location $curDir
[string]$lib = "$curDir\lib"
$curDate = Get-Date -Format "ddMMyyyy"
[string]$logPath = $curDir + "\log"
[string]$logName = $logPath + "\" + $curDate + "_sync.log"

[string]$remotePath = "$curDir\inMoscow"
#[string]$remotePath = "s:\OBMEN\IN_QUORUM"
[string]$inPath = "$curDir\in"
[string]$outPath = "$curDir\out"
[string]$robo = "$lib\robocopy32.exe"

. $lib/PSMultiLog.ps1
. $lib/libs.ps1

Clear-Host

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

#проверяем существуют ли нужные пути и файлы
testDir(@($remotePath))
createDir(@($inPath, $outPath))
testFiles(@($robo))

function remoteSync {
    param (
        [string]$remotePath,
        [string]$inPath,
        [string]$logPath
    )
    $AllArgs = @($remotePath, $inPath, "/LOG+:$logPath\robocopy.log", '/LEV:0', '/PURGE', '/ZB', '/R:30', '/W:10', '/TBD', '/TEE', '/ETA')
    &"$robo" $AllArgs
}

function createHierarchy {
    param (
        [string]$inPath
    )

}
Write-Log -EntryType Information -Message "Начало работы syncQuorum"

remoteSync -remotePath $remotePath -inPath $inPath -logPath $logPath

Write-Log -EntryType Information -Message "Конец работы syncQuorum"

Stop-FileLog
Stop-HostLog