[string]$dir1 = "c:\form440p"
[string]$lib = "$dir1\lib"

. $dir1/variables.ps1
. $lib/PSMultiLog.ps1
. $lib/libs.ps1
. $lib/libsVerba.ps1

function copyXml{
    Write-Log -EntryType Information -Message "Копируем xml-файлы $testDir --> $work"
    Remove-Item -Path "$work\*.*"
    Copy-Item -Path "$testDir\*.xml" -Destination $work -Force		
}

Set-Location $dir1

ClearUI

Start-HostLog -LogLevel Information

$curDate = Get-Date -Format "ddMMyyyy"
[string]$logName440 = (Get-Item $PSCommandPath ).DirectoryName + "\log\" + $curDate +"_f440-test.log"
$testDir = "$dir1\testing\xml"

Start-FileLog -LogLevel Information -FilePath $logName440 -Append

Write-Log -EntryType Information -Message "Загружаем ключевую дискету $disk_sig_send"
Copy_dirs -from $disk_sig_send -to 'a:'		

Write-Log -EntryType Information "Старый вариант функции Verba_script"
copyXML
$startDTM = (Get-Date)
Verba_script -scrpt_name $script_sig -mask "*.*"
Write-Log -EntryType Warning "Elapsed Time: $(($(Get-Date)-$startDTM).totalseconds) seconds"

Write-Log -EntryType Information "Функция Verba_script без проверки"
copyXML
$startDTM = (Get-Date)
Verba_script_no -scrpt_name $script_sig -mask "*.*"
Write-Log -EntryType Warning "Elapsed Time: $(($(Get-Date)-$startDTM).totalseconds) seconds"


Stop-FileLog
Stop-HostLog