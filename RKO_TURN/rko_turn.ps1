$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
$out_dir = "k:/"
$file1 = "RKO_TURN.XLT"

Clear-Host
Set-Location $out_dir

Write-Host -ForegroundColor Blue 'Search...'
$Files = Get-ChildItem -Path $out_dir -Filter $file1 -Recurse -ErrorAction SilentlyContinue

ForEach ($File in $Files){
	Copy-Item -Path $dir1/$file1 -Destination $File.DirectoryName -Force
	Write-Host -ForegroundColor DarkCyan $File.DirectoryName 	
}

Write-Host -ForegroundColor Blue 'Finish'