$put1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

$work = "\\tmn-ts-01\Protokol"
$arch = "\\tmn-ts-01\Protokol\old"
$notepad = "c:\Windows\notepad.exe"

Clear-Host
Set-Location $work

$mask = "*.xml"

[int]$f_count = (Get-ChildItem "$mask" | Measure-Object).Count
if ($f_count -eq 0){
    Write-Host "Файлы не найдены!" -ForegroundColor Red    
    exit
}

Write-Host "Убираем ЭЦП" -ForegroundColor Green
$files1 = Get-ChildItem $mask

foreach ($file1 in $files1){
	
	$aaa = "$work\temp.txt"
	if (Test-Path $aaa){
		Remove-Item $aaa
	}
	
	$content = Get-Content $file1
	$num = $content.Length;

	$flag = $false
	Write-Host "$file1" -ForegroundColor Green
	
	for ($i = 0; $i -lt $num; $i++){
		$l1 = $content[$i];	
		
		if ($l1 -match '</Файл>'){
			$flag = $true
			$l1 = "</Файл>"
		}
		
		$l1 | Out-File -filepath $aaa -Encoding utf8 -Append
		if ($flag){
			break
		} 		
	}
	Remove-Item -Path $file1
	Rename-Item -Path $aaa -NewName $file1.Name 
}

Write-Host -ForegroundColor Green "Создаем каталог архива"
$dt1 = Get-Date -Format "ddMMyyyy"
$arch_dir = -join ($arch, '\', $dt1)
if (!(Test-Path -Path $arch_dir )){
	New-Item -ItemType directory $arch_dir -Force | out-null	
}

Write-Host "Печать файлов" -ForegroundColor Green
$files1 = Get-ChildItem $mask

foreach ($file1 in $files1){
	Move-Item -Path $file1 -Destination $arch_dir 
	$f_name = $file1.Name
	$path1 = "$arch_dir\$f_name"
	Write-Host "$path1" -ForegroundColor Green
	& $notepad $path1
}