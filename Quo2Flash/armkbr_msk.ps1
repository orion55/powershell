#программа копирования файлов из кворума на флешку обычных платежей и копирование из в СМЭВ
#переменные

$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#исходный путь
#$orig_path = "m:\cb_out"
#$orig_path = "$dir1\cb_out"
$orig_path = "\\191.168.6.12\quorum\TMN\SENDDOC\CB_OUT"

#путь московсого сервера
$mosk_path = "\\191.168.7.14\store\СМЭВ\TUMEN\IN"
#$mosk_path = "$dir1\test_msk"
$mosk_path_two = "\\191.168.7.14\store\gis_hcs\TMN\IN"
#$mosk_path_two = "$dir1\test_msk_two"
$user1 = "tmn\tmn-svc_smev"
$pass1 = "ep6UN!vB0n"
#$mosk_path = "\\192.168.72.17\disk_O\test1"
#$mosk_path_two = "\\192.168.72.17\disk_O\test2"
#$user1 = "tmn\admsrv"
#$pass1 = "99ty95q(Ls"

$to = @("tmn_oit@tmn.apkbank.apk")
#$to = @("tmn-goe@tmn.apkbank.ru")

#Очищаем экран и устанавливаем цвета
function ClearUI{
	$bckgrnd = "DarkBlue"
	$Host.UI.RawUI.BackgroundColor = $bckgrnd
	$Host.UI.RawUI.ForegroundColor = 'White'
	$Host.PrivateData.ErrorForegroundColor = 'Red'
	$Host.PrivateData.ErrorBackgroundColor = $bckgrnd
	$Host.PrivateData.WarningForegroundColor = 'Magenta'
	$Host.PrivateData.WarningBackgroundColor = $bckgrnd
	$Host.PrivateData.DebugForegroundColor = 'Yellow'
	$Host.PrivateData.DebugBackgroundColor = $bckgrnd
	$Host.PrivateData.VerboseForegroundColor = 'Green'
	$Host.PrivateData.VerboseBackgroundColor = $bckgrnd
	$Host.PrivateData.ProgressForegroundColor = 'Cyan'
	$Host.PrivateData.ProgressBackgroundColor = $bckgrnd
	Clear-Host
}

#переименовываем файлы в формате YYYYMMDDNNN.xml
function fname($filename){
	$date1 = $filename.LastWriteTime
	$dt = "{0:yyyy}{0:MM}{0:dd}" -f $date1
	$ext1 = $file1.Extension
	$ext1 = $ext1.substring(1, 3)
	$file2 = -join ($dt, $ext1, ".xml")	
	return $file2
}

#переименовываем файлы обратно в формате a1206962.001
function revName($filename){
	$num = $filename.Name.split('.')[0].Substring(8,3)
	$file = Get-ChildItem "a*.$num" -path $orig_path	
	return $file.Name
}

#Печатаем список файлов, которые не удалось скопировать
function printList($difF){
	$list = ''
	foreach($file in $difF){
		$revName = revName($file)
		$name = $file.Name
	    $list = -join ($orig_path, "\", $revName, " => $name", "`n")
	}
	return $list
	
}

#переименовываем файлы обратно в формате a1206962.001, но работаем со строками
function revNameTwo($filename){
	$num = $filename.split('.')[0].Substring(8,3)
	$file = Get-ChildItem "a*.$num" -path $orig_path	
	return $file.Name
}

#удаляем дубликаты и переименовываем те файлы, которые успешно скопировались
function renameDiff($list1, $list2){	
	$list = @()
	foreach($file in $list1){
		$list += $file.Name
	}
	foreach($file in $list2){
		$list += $file.Name
	}	
	$list = $list | Sort-Object -Unique
	
	$listFiles = @()
	foreach($file in $list){
		$listFiles += revNameTwo($file)
	}
	
	$files = Get-ChildItem "a*.0??" -path $orig_path	
	foreach($file1 in $files){		
		if (!($listFiles -match $file1)){
			$ext1 = $file1.Extension.substring(2, 2)		
			$newFile = -join ($file1.BaseName, '.!', $ext1)
			Rename-Item $file1 -NewName $newFile -force
		}		
	}
}

#основной код программы
Import-Module BitsTransfer
Set-Location $orig_path
ClearUI
Write-Host -ForegroundColor White "Запуск скрипта..."

#проверка существования путей
if (!(Test-Path -Path $orig_path)){
	Write-Host -ForegroundColor Red "Путь $orig_path не найден!"	
	Exit
}

#конвертируем логин\пароль
$Password = ConvertTo-SecureString $pass1 -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential($user1, $Password)

#находим все файлы имя которых начинается на a*.0??
$files = Get-ChildItem "a*.0??" -path $orig_path
if ($files -eq $null){
	Write-Host -ForegroundColor Cyan "Файлы $orig_path\a*.0?? не найдены."	
	Exit
}

#Копируем файлы на московский сервер
foreach ($file1 in $files){	
	
	#конвертируем имя файл в *.xml
	$file21 = fname($file1)
	Copy-Item $file1 -Destination $file21 -force
	Write-Host -ForegroundColor Green "$orig_path\$file1 ($file21) => $mosk_path"
	
	#копируем файлы на первый московский сервер
	$job = Start-BitsTransfer –source $file21 -destination $mosk_path -Authentication NTLM -Credential $mycreds -asynchronous -Priority low	
	while( ($job.JobState.ToString() -eq 'Transferring') -or ($job.JobState.ToString() -eq 'Connecting') )
	{
		Sleep 3		
	}	
	Complete-BitsTransfer -BitsJob $job
	
	#копируем файлы на второй московский сервер
	Write-Host -ForegroundColor Green "$orig_path\$file1 ($file21) => $mosk_path_two"
	$job = Start-BitsTransfer –source $file21 -destination $mosk_path_two -Authentication NTLM -Credential $mycreds -asynchronous -Priority low
	while( ($job.JobState.ToString() -eq 'Transferring') -or ($job.JobState.ToString() -eq 'Connecting') )
	{
		Sleep 3
	}
	Complete-BitsTransfer -BitsJob $job	
}

#Удаляем файлы имитируем потери связи при отладке!!!
#Remove-Item "$mosk_path\20160812002.xml"
#Remove-Item "$mosk_path_two\20160812002.xml"
#Remove-Item "$mosk_path_two\20160812002.xml"

#Проверка всё ли корректно скопировали
$refContents = Get-ChildItem "$orig_path\*.xml"
$difContents = Get-ChildItem "$mosk_path\*.xml"

#проверка первого сервера
if (($difContents|Measure-Object).count -gt 0){
	$difFiles = Compare-Object -ReferenceObject $refContents -DifferenceObject $difContents -Property ('Name', 'Length') -PassThru |  where-object { $_.SideIndicator -eq '<='} | select Name	
} else {
	$difFiles = $refContents
}
$countMsk = ($difFiles|Measure-Object).count

#проверка второго сервера
$difContents = Get-ChildItem "$mosk_path_two\*.xml"
if (($difContents|Measure-Object).count -gt 0){
	$difFiles_two = Compare-Object -ReferenceObject $refContents -DifferenceObject $difContents -Property ('Name', 'Length') -PassThru |  where-object { $_.SideIndicator -eq '<='} | select Name
} else {
	$difFiles_two = $refContents
}
$countMsk_two = ($difFiles_two|Measure-Object).count

#удаляем преобразованные xml
Remove-Item "$orig_path\*.xml"

#если нет ошибок при копировании переименовываем файлы в *.!* и выходим из скрипта
if ($countMsk -eq 0 -and $countMsk_two -eq 0){	
	$files = Get-ChildItem "a*.0??" -path $orig_path
	foreach($file1 in $files){		
		$ext1 = $file1.Extension.substring(2, 2)		
		$newFile = -join ($file1.BaseName, '.!', $ext1)
		Rename-Item $file1 -NewName $newFile -force
	}
	Write-Host 'Всё хорошо!'
	Exit
}

#если ошибки при копировании есть
#переименовываем файлы, которые удалось корреткно скопировать
renameDiff($difFiles, $difFiles_two)

#пишем письмо с ошибкой
if ($countMsk -gt 0){	
	$mskList = printList($difFiles)
}

if ($countMsk_two -gt 0){
	$mskListTwo = printList($difFiles_two)
}

$text1 = ''
if ($countMsk -gt 0){
	$text1 = "Файлы не удалось скопировать на $mosk_path`n"
	$text1 += $mskList
}

$text2 = ''
if ($countMsk_two -gt 0){
	$text2 = "Файлы не удалось скопировать на $mosk_path_two`n"
	$text2 += $mskListTwo
}

$body = -join($text1, "`n", $text2, "`nПроверьте подключение к московскому серверу!")
Write-Host -ForegroundColor Red "Ошибка!`n$body"
		
$nowDate = Get-Date
$subject = "Ошибка копирования файлов СМЭВ - $nowDate"
$from = "tmn-goe@tmn.apkbank.apk"
$smtpHost = "191.168.6.50"
	
$email = New-Object System.Net.Mail.MailMessage 
foreach($mailTo in $to){
    $email.To.Add($mailTo)
}
 
$email.From = $from
$email.Subject = $subject
$email.Body = $body
	 
$client = New-Object System.Net.Mail.SmtpClient $smtpHost
#использовать текущий логин\пароль для авторизации на почтовом сервере
$client.UseDefaultCredentials = $true
$client.Send($email)
	
Write-Host "Письмо отправленно..." -ForegroundColor Green

Write-Host -ForegroundColor White "Конец работы скрипта..."