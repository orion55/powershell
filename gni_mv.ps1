$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
#$orig_dir = "$dir1\in"
#$dest_dir = "$dir1\out"
$orig_dir = "\\191.168.6.12\quorum\tmn\SENDDOC\365P\CB_OUT\GNI"
$dest_dir = "\\tmn-ts-01\GNI"

Clear-Host
Set-Location $orig_dir

if (!(Test-Path -Path $orig_dir)){
	Write-Host "Путь $orig_dir не найден!" -ForegroundColor Red
	Write-Host "Нажмите любую клавишу для продолжения" 
	Read-Host "Нажмите Enter"			
	Exit
}

if (!(Test-Path -Path $dest_dir)){
	Write-Host "Путь $orig_dir не найден!" -ForegroundColor Red
	Write-Host "Нажмите любую клавишу для продолжения" 
	Read-Host "Нажмите Enter"			
	Exit
}

Move-Item -Destination $dest_dir -Path "$orig_dir\SBC*.XML" -Force
Write-Host -ForegroundColor Green "Перемещение файлов выполненно!"