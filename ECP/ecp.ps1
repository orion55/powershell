#каталог выполнения скрипта
$orig_path = "\\191.168.6.12\quorum\tmn\SENDDOC\365P\CB_OUT\GNI\RESOL_GNI_NEW"

$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

Clear-Host
Set-Location $dir1
$out_dir = "$dir1\OUT"

$count1 = Get-ChildItem "$orig_path\*.txt"

if ($count1.length -eq $null){
	Write-Host -ForegroundColor Red  "Файлы в $orig_path не найдены!"
	exit
}

Remove-Item "$out_dir\*.txt"

Write-Host "Копируем файлы из $orig_path в $out_dir" -ForegroundColor Green
Copy-Item -Path "$orig_path\*.txt" -Destination $out_dir -Force

Write-Host "Конвертируем dos -> win" -ForegroundColor Green
$files1 = Get-ChildItem "$out_dir\*.txt"

foreach ($file1 in $files1){
	./dostowin.exe $file1 > $null
}

Write-Host "Обрабатываем файлы" -ForegroundColor Green	
foreach ($file1 in $files1){
	
	$aaa = "$out_dir\temp.txt"
	if (Test-Path $aaa){
		Remove-Item $aaa
	}
	
	$content = Get-Content $file1
	$num = $content.Length;

	$flag = $false
	Write-Host "$file1" -ForegroundColor Green
	
	for ($i = 0; $i -lt $num; $i++){
		$l1 = $content[$i];	
		
		if ($l1 -match '==='){
			$flag = $true				
		}
		
		$l1 | Out-File -filepath $aaa -Encoding utf8 -Append
		if ($flag){
			break
		} 		
	}
	Remove-Item -Path $file1
	Rename-Item -Path $aaa -NewName $file1.Name 
}