#исходный путь
$orig_path="\\tmn-eed-01\UfebsOut"
#путь назначения
$dest_path="C:\UTA\XML\OUT"

Clear-Host

#проверка существования путей
if (!(Test-Path -Path $orig_path)){
	Write-Error "Путь $orig_path не найден!"
#	Write-Host "Нажмите любую клавишу для продолжения" 
#	$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Exit
}

if (!(Test-Path -Path $dest_path)){
	Write-Error "Путь $dest_path не найден!"
#	Write-Host "Нажмите любую клавишу для продолжения" 
#	$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Exit
}

Set-Location $orig_path

$files = Get-ChildItem "*.*" -path $orig_path
if ($files -ne $null){
	foreach ($file1 in $files){
		Write-Output $file1.fullname
		$name1 = $file1.name
			
		Copy-Item $file1 -Destination $dest_path
		if (Test-Path("$dest_path\$name1")){
			Remove-Item $file1
		} else {
			Write-Error "Файл $file1 не скопирован в $dest_path!"	
		}
		
	}
} else {
	Write-Output "Файлы не найдены!"
}