#Программа копирования с флешки в EDSmart и создание архива с разбивкой по датам v2
#(с) Гребенёв О.Е. 15.07.2020
[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

$inDir = "$curDir\test\in"
$outDir = "$curDir\test\out"
$archiveDir = "$curDir\test\archive"

function moveFiles {
    param (
        $inXml,
        [string]$outDir
    )
    $msg = $inXml | Move-Item -Destination $outDir -ErrorAction Stop -Verbose -Force *>&1
    Write-Log -EntryType Information -Message ($msg | Out-String)
    Write-Log -EntryType Information -Message "Файл(ы) перемещен(ы) в $outDir"
}

function decodeText {
    param (
        $text
    )
    $encFrom = [System.Text.Encoding]::GetEncoding('windows-1251')
    $encTo = [System.Text.Encoding]::GetEncoding('utf-8')

    $bytes = [System.Convert]::FromBase64String($text)
    $bytes = [System.Text.Encoding]::Convert($encFrom, $encTo, $bytes)
    return $encTo.GetString($bytes)
}
function copyToArchive {
    param (
        [string]$inDir,
        [string]$archiveDir
    )

    $inFiles = Get-ChildItem $($inDir + '\*') -File -Include *.ed, *.eds, *.0*, *.1*, *.xml
    foreach ($file in $inFiles) {
        [xml]$xmlData = Get-Content $file
        $text = $xmlData.SigEnvelope.Object

        [xml]$xmlRecord = decodeText -text $text

        #$xmlRecord.save("d:\$($file.Name).xml")
        if ($null -ne $xmlRecord.ChildNodes[1]) {
            if ($null -ne $xmlRecord.ChildNodes[1].EDDate) {
                $date = $xmlRecord.ChildNodes[1].EDDate
            }
            else {
                $date = Get-Date -Format "yyyy-MM-dd"
            }
            $arrDate = $date.split("-")

            $newPath = $archiveDir + "\" + $arrDate[0] + "\" + $arrDate[1] + "\" + $arrDate[2]
            New-Item -path $newPath -type directory -ErrorAction Ignore > $null

            $msg = $file | Copy-Item -Destination $newPath -ErrorAction Stop -Verbose -Force *>&1
            Write-Log -EntryType Information -Message ($msg | Out-String)
        }
    }
}

Set-Location $curDir

. $curDir/libs/lib.ps1
. $curDir/libs/PSMultiLog.ps1

#ClearUI
Clear-Host

testDir(@($inDir, $outDir))
createDir(@($archiveDir))

$logDir = "$curDir\log"
createDir($logDir)

$dt = Get-Date -Format "dd-MM-yyyy"
$logName = $logDir + "\" + $dt + "_LOG.log"

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

$inXml = Get-ChildItem -Path $inDir "*" -File
$count = ($inXml | Measure-Object).count
if ($count -eq 0) {
    Write-Log -EntryType Error -Message "Не найдены файлы в $inDir"
    Stop-FileLog
    Stop-HostLog
    exit
}
else {
    try {
        copyToArchive -inDir $inDir -archiveDir $archiveDir
        moveFiles -inXml $inXml -outDir $outDir
    }
    catch {
        Write-Log -EntryType Error -Message "Ошибка перемещения файла(ов) в $outDir"
        exit
    }
}

Stop-FileLog
Stop-HostLog