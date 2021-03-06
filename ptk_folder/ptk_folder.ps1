$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#$orig_dir = "$dir1\in"
#$dest_dir = "$dir1\out"
$orig_dir = "c:\UTA\SR\OTCHET\PTKPSD\CAB"
$dest_dir = "l:\PTK PSD\Cab"


Clear-Host
Set-Location $dir1

$last = Get-ChildItem "$orig_dir\*.arj" | Where-Object {$_.BaseName -Match "[0-9]{4}"} | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$last_date = $last.LastWriteTime.Date
$last_arj = Get-ChildItem "$orig_dir\*.arj" | Where-Object {$_.BaseName -Match "[0-9]{4}"} | Where{$_.LastWriteTime -ge $last_date}

foreach ($file1 in $last_arj){
	Write-Host -ForegroundColor Blue "Обрабатываем файл $file1"
	$name1 = $file1.BaseName
	$dir2 = "$dest_dir\$name1"
	if (!(Test-Path($dir2))){
		New-Item -Path "$dest_dir\$name1" -ItemType Directory | out-null
		
		$AllArgs = @('e', $file1, $dir2)
		&"$dir1\arj.exe" $AllArgs | out-null
		Write-Host -ForegroundColor Green "Файл распакован в $dir2"
	} else {
		Write-Host -ForegroundColor Green "Каталог $dir2 существует, файл пропущен"
	}
}