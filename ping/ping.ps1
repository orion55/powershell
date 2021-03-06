#$servers = "tmn-dc-01","tmn-dc-033"
$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
Set-Location $dir1
Clear-Host

$servers = Get-Content "comp.txt"
Foreach($s in $servers){
  if(!(Test-Connection -Cn $s -BufferSize 16 -Count 1 -ea 0 -quiet))  {
   	"Problem connecting to $s"
   } else {
   	Write-Host -ForegroundColor Blue "Connecting to $s"
   }
} # end foreach