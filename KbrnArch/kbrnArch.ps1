#Программа копирования файлов с логированием и архивацией
#Версия 1.2

[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#$inDir = @("$curDir\testCLI\in")
#$archDir = "$curDir\testCLI\in\arch"
#$outDir = "$curDir\testCLI\out"

#[0] -> rcv; [1] -> info; [2] -> err
$inDir = @("$curDir\testRCV\in\rcv", "$curDir\testRCV\in\info", "$curDir\testRCV\in\err")
$archDir = "$curDir\testRCV\in\arch"
$outDir = "$curDir\testRCV\out"


Set-Location $curDir

. $curDir/libs/lib.ps1
. $curDir/libs/PSMultiLog.ps1

ClearUI

testDir($inDir)

$logDir = "$curDir\log"
createDir($logDir)
createDir($outDir)
testDir($outDir)

$dt = Get-Date -Format "dd-MM-yyyy"
$logName = $logDir + "\" + $dt + "_LOG.log"

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

$curDate = Get-Date -Format "ddMMyyyy"

$archDirFull = "$archDir\$curDate"
if (!(Test-Path -Path $archDirFull )){
	New-Item -ItemType directory $archDirFull -Force | out-null
}

$inXml = Get-ChildItem -Path $inDir[0] "*" -File
$count = ($inXml | Measure-Object).count
if ($count -eq 0){
    Write-Log -EntryType Error -Message "Не найдены файлы в $($inDir[0])"
    Stop-FileLog
    Stop-HostLog
    exit
} else {
    try {
        $msg = Get-ChildItem $($inDir[0]+'\*') -Include *.ed, *.eds, *.xml, *.0* | Copy-Item -Destination $outDir -ErrorAction Stop -Verbose -Force *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)  
        Write-Log -EntryType Information -Message "Файл(ы) скопирован(ы) в $outDir"
    }
    catch {    
        Write-Log -EntryType Error -Message "Ошибка копирования файла(ов) в $outDir"
        exit
    }

    try {    
        $msg = $inXml | Move-Item -Destination $archDirFull -ErrorAction Stop -Verbose -Force *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)  
        Write-Log -EntryType Information -Message "Файл(ы) перемещен(ы) в $archDirFull"
    }
    catch {    
        Write-Log -EntryType Error -Message "Ошибка перемещения файла(ов) в $archDirFull"
        exit
    }
}

if ([bool]$inDir[1]){
    $infoXml = Get-ChildItem -Path $inDir[1] "*" -File
    $count = ($infoXml | Measure-Object).count
    if ($count -ne 0){
        
        $archDirFullInfo = "$archDirFull\info"
        if (!(Test-Path -Path $archDirFullInfo )){
	        New-Item -ItemType directory $archDirFullInfo -Force | out-null
        }

        try {
            $msg = $infoXml | Copy-Item -Destination $outDir -ErrorAction Stop -Verbose -Force *>&1    
            Write-Log -EntryType Information -Message ($msg | Out-String)  
            Write-Log -EntryType Information -Message "Файл(ы) скопирован(ы) в $outDir"
        }
        catch {    
            Write-Log -EntryType Error -Message "Ошибка копирования файла(ов) в $outDir"
            exit
        }

        try {
            $msg = $infoXml | Move-Item -Destination $archDirFullInfo -ErrorAction Stop -Verbose -Force *>&1
            Write-Log -EntryType Information -Message ($msg | Out-String)  
            Write-Log -EntryType Information -Message "Файл(ы) перемещен(ы) в $archDirFullInfo"
        }
        catch {    
            Write-Log -EntryType Error -Message "Ошибка перемещения файла(ов) в $archDirFullInfo"
            exit
        } 
    }
}

$flagErr = $false
if ([bool]$inDir[2]){
    $errXml = Get-ChildItem -Path $inDir[2] "*" -File
    $count = ($errXml | Measure-Object).count
    if ($count -ne 0){
        $flagErr = $true
        
        $archDirFullErr = "$archDirFull\err"
        if (!(Test-Path -Path $archDirFullErr )){
	        New-Item -ItemType directory $archDirFullErr -Force | out-null
        }

        try {
            $msg = $errXml | Copy-Item -Destination $outDir -ErrorAction Stop -Verbose -Force *>&1    
            Write-Log -EntryType Information -Message ($msg | Out-String)  
            Write-Log -EntryType Information -Message "Файл(ы) скопирован(ы) в $outDir"
        }
        catch {    
            Write-Log -EntryType Error -Message "Ошибка копирования файла(ов) в $outDir"
            exit
        }

        try {
            $msg = $errXml | Move-Item -Destination $archDirFullErr -ErrorAction Stop -Verbose -Force *>&1    
            Write-Log -EntryType Information -Message ($msg | Out-String)  
            Write-Log -EntryType Information -Message "Файл(ы) перемещен(ы) в $archDirFullErr"
        }
        catch {    
            Write-Log -EntryType Error -Message "Ошибка перемещения файла(ов) в $archDirFullErr"
            exit
        }
    }
}


if ($flagErr){
    Write-Log -EntryType Error -Message "Пришли сообщения об ошибках из ТШ КБР"
    Read-Host "Нажмите Enter"
}

Stop-FileLog
Stop-HostLog