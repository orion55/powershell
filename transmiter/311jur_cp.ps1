[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

$work_dir = "c:\WORK"
#$work_dir = "$curDir\Work"

$311dir = "\\tmn-ts-01\311jur"
#$311dir = "$curDir\311jur"

$logDir = "$311dir\log"
$archiveDir = "$311dir\Archive"

Set-Location $curDir

. $curDir/lib/libs.ps1
. $curDir/lib/PSMultiLog.ps1


testDir(@($311dir, $work_dir))
createDir(@($logDir, $archiveDir))

#есть ли xml-файлы в каталоге work?
$xml1 = Get-ChildItem "$work_Dir\*.xml"
$count = ($xml1|Measure-Object).count
if ($count -eq 0){
	Write-Host -ForegroundColor Red "Файлы в $work_dir не обнаружены!"
	exit
}

$dt = Get-Date -Format "dd-MM-yyyy"
$logName = $logDir+ "\" + $dt + "_LOG.log"

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

$curDate = Get-Date -Format "ddMMyyyy"

$archDirFull = "$archiveDir\$curDate"
if (!(Test-Path -Path $archDirFull )){
	New-Item -ItemType directory $archDirFull -Force | out-null	
}

$workXml = Get-ChildItem -Path $work_dir "*.xml"
$countWork = ($workXml | Measure-Object).count
if ($countWork -eq 0){
    Write-Log -EntryType Error -Message "Не найдены файлы в $work_dir"
} else {
    try {
        Write-Log -EntryType Information -Message "Резервное копирование файлов в $archDirFull"
        $msg = Copy-Item "$work_dir\*.xml" -Destination $archDirFull -ErrorAction Stop -Verbose -Force *>&1    
        Write-Log -EntryType Information -Message ($msg | Out-String)  
        Write-Log -EntryType Information -Message "Файл(ы) скопирован(ы) в $archDirFull"
    }
    catch {    
        Write-Log -EntryType Error -Message "Ошибка копирования файла(ов) в $archDirFull"
        exit
    }
}

Stop-FileLog
Stop-HostLog