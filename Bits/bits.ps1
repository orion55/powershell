$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

$dest = "\\192.168.72.17\disk_O\test1"

Import-Module BitsTransfer
Start-BitsTransfer –source  "$dir1\i1106962.005" -destination $dest