cls
[string]$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

. $dir1\PSMultiLog.ps1

$logName = (Get-Item $PSCommandPath ).DirectoryName + "\Log\" + (Get-Item $PSCommandPath ).BaseName + '.log'

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

Write-Log -EntryType Information -Message "This is a sample log message."
Write-Log -EntryType Warning -Message "This is a sample warning."
Write-Log -EntryType Error -Message "This is a sample error."

Stop-FileLog
Stop-HostLog