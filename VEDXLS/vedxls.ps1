$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
Set-Location $dir1

$out_file = "U:\Fedorova\OUT\SALDO3.out"

Clear-Host

if (!(Test-Path "$out_file")){
	Write-Host "Файл $out_file не найден!" -ForegroundColor Red
	Exit
}

$l = Get-Item $out_file
if ($l.Length -eq 0){
	Write-Host "Длина файла $out_file нулевая!" -ForegroundColor Red
	Exit
}
$tmp1 = "$dir1\tmp"

if (!(Test-Path $tmp1)){
	New-Item -Path $tmp1 -ItemType "directory" | Out-Null
}

$out_file1 = "$tmp1\SALDO3.out"

if (Test-Path "$out_file1"){
	Remove-Item "$out_file1"
}
Copy-Item $out_file $tmp1

Write-Host "Конвертируем dos -> win" -ForegroundColor Green
./dostowin.exe $out_file1 | Out-Null

$aaa = "$tmp1\aaa.txt"
if (Test-Path $aaa){
	Remove-Item $aaa
}

#список лексем-исключений
$lex = @("¦       счета", "¦=====", "¦       Номер", "¦      лицевого", "¦             ИТОГО:")

$content = Get-Content "$out_file1"
$num = $content.Length;

#фильтруем - убираем шапку и хвост таблицы
Write-Host "Фильтрация" -ForegroundColor Green	
for ($i = 0; $i -lt $num; $i++){
	$l1 = $content[$i];	
	
	if ($l1[0] -eq '¦'){
		$flag = $true
		foreach ($lex1 in $lex){
			if ($l1 -match $lex1){
				$flag = $false				
			}				
		}		
		if ($flag){
			$l1 = $l1.Replace("""", "'")
			$l1.Substring(1) | Out-File -filepath $aaa -Encoding utf8 -Append			 
		}		
	}	
}

#сцепляем наименования организаций
Write-Host "Преобразуем в csv" -ForegroundColor Green	
$csv1 = Import-Csv -Path $aaa -Delimiter "¦" -Header "Лицевой счет", "Наименование л. с.", "Дата п/о", "Кол.операций", "Дебет", "Кредит", "Сальдо д.", "Сальдо к."
for($i = 0; $i -lt $csv1.Count; $i++){
  $csv1[$i]."Наименование л. с." = $csv1[$i]."Наименование л. с.".trimend()
  
  if ($csv1[$i]."Лицевой счет".length -eq 0){
  	$pred = $i - 1
  	While ($csv1[$pred]."Лицевой счет".length -eq 0){
		$pred--
	}	
	$csv1[$pred]."Наименование л. с." = -join($csv1[$pred]."Наименование л. с.", " ", $csv1[$i]."Наименование л. с.")
  }
}

$csv1 = $csv1 | ? {$_."Лицевой счет".length -ne 0}

foreach ($c1 in $csv1){
	$c1."Кол.операций" = $c1."Кол.операций".replace(".", ",")
	$c1."Дебет" = $c1."Дебет".replace(".", ",")
	$c1."Кредит" = $c1."Кредит".replace(".", ",")
	$c1."Сальдо д." = $c1."Сальдо д.".replace(".", ",")
	$c1."Сальдо к." = $c1."Сальдо к.".replace(".", ",")
}

$aaa_csv = "$tmp1\aaa.csv"
$csv1 | Export-Csv -Path $aaa_csv -Encoding UTF8 -UseCulture -NoTypeInformation

$fileName = "result_" + (Get-Date -Format "dd-MM-yyyy") + ".xlsx"

if (Test-Path "$dir1\$fileName"){
	Remove-Item "$dir1\$fileName"
}

Write-Host "Запускаем Excel" -ForegroundColor Green
&"$dir1\shab2.xlsm"