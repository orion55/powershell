Clear-Host

Get-Process xstart* | Stop-Process -Force
Write-Host "xStarter kill" -foreground "green"

Start-Sleep -Seconds 10

Write-Host "xStarter start" -foreground "green"
$dir1 = "${Env:ProgramFiles}"
Start-Process "$dir1\xStarter\xStarter.exe"