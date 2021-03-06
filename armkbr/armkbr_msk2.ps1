#программа копирования файлов из кворума на флешку обычных платежей и копирование из в СМЭВ
#переменные

$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#исходный путь
#$orig_path = "m:\cb_out"
$orig_path = "$dir1\cb_out"
#$orig_path = "\\191.168.6.12\quorum\TMN\SENDDOC\CB_OUT"

$besp_path = "$dir1\exp"
#$besp_path = "\\191.168.6.12\quorum\TMN\SENDDOC\CB_OUT\BESP\exp"

#путь московсого сервера
#$mosk_path = "\\191.168.7.14\store\СМЭВ\TUMEN\IN"
$mosk_path = "$dir1\test_msk"
#$mosk_path_two = "\\191.168.7.14\store\gis_hcs\TMN\IN"
$mosk_path_two = "$dir1\test_msk_two"
#$mosk_path = "\\192.168.72.17\disk_O\test1"
#$mosk_path_two = "\\192.168.72.17\disk_O\test2"

#$to = @("tmn_oit@tmn.apkbank.apk")
$to = @("tmn-goe@tmn.apkbank.ru")

#имя лог-файла
$curDate = Get-Date -Format "ddMMyyyy"
$log_path = "$dir1\log"
[string]$logName = $log_path + '\' + $curDate +"_armkbr.log"

$tmp_path = "$dir1\tmp"

. $dir1/script/PSMultiLog.ps1

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

function Test_dir($dirs1){	
	foreach ($d1 in $dirs1){
		#проверка существования путей
		if (!(Test-Path -Path $d1)){
			Write-Log -EntryType Error -Message "Путь $d1 не найден!"
			Write-Log -EntryType Information -Message "Нажмите любую клавишу для продолжения" 
			Read-Host "Нажмите Enter"			
			Exit
		}
	}
}

function Create_dir($dirs1){	
	foreach ($d1 in $dirs1){
		#проверка существования путей
		if (!(Test-Path -Path $d1)){
			New-Item -ItemType directory -Path $d1 | out-Null
		}
	}
}

#переименовываем файлы в формате YYYYMMDDNNN.xml
function fname{
    Param( 
	    $filename,
        [string]$extFile
    )
    
	$date1 = $filename.LastWriteTime
	$dt = "{0:yyyy}{0:MM}{0:dd}" -f $date1
	$ext1 = $file1.Extension
	$ext1 = $ext1.substring(1, 3)
	$file2 = -join ($dt, $ext1, $extFile)	
	return $file2
}

function CopyRemote{    
    Param( 
	    [string]$pathServer,
        [string]$maskFiles,
        [string]$extFile
    )    

    $files = Get-ChildItem "$maskFiles" -path $pathServer    
    if ($files -eq $null){
	    Write-Host -ForegroundColor Yellow "Файлы $pathServer\$maskFiles не найдены!"	
	    return -1;
    }
    
    Remove-Item "$tmp_path\*.*"
    $msg = $files | Copy-Item -Destination $tmp_path -Verbose -Force *>&1
    Write-Log -EntryType Information -Message ($msg | Out-String)    
    
    $files_tmp = Get-ChildItem "$maskFiles" -path $tmp_path
    foreach ($file1 in $files_tmp){		
	    #конвертируем имя файл в *.xml
	    $file21 = fname -filename $file1 -extFile $extFile        
        $msg = Rename-Item $file1.FullName -NewName $file21 -Verbose -Force *>&1
        Write-Log -EntryType Information -Message ($msg | Out-String)
    }
    
    $msg = Copy-Item -Path "$tmp_path\*.xml" -Destination $mosk_path -Verbose -Force *>&1
    Write-Log -EntryType Information -Message ($msg | Out-String)    

    $msg = Copy-Item -Path "$tmp_path\*.xml" -Destination $mosk_path_two -Verbose -Force *>&1
    Write-Log -EntryType Information -Message ($msg | Out-String)

    #Удаляем файлы имитируем потери связи при отладке!!!
    #Remove-Item "$mosk_path\20180425001.xml"
    #Remove-Item "$mosk_path_two\20180425001.xml"
    #Remove-Item "$mosk_path_two\20180424001b.xml"

    #Проверка всё ли корректно скопировали
    $refContents = Get-ChildItem "$tmp_path\*$extFile"
    $difContents = Get-ChildItem "$mosk_path\*$extFilel"

    #проверка первого сервера
    if (($difContents|Measure-Object).count -gt 0){
	    $difFiles = Compare-Object -ReferenceObject $refContents -DifferenceObject $difContents -Property ('Name', 'Length') -PassThru |  where-object { $_.SideIndicator -eq '<='} | select Name	
    } else {
	    $difFiles = $refContents
    }
    $countMsk = ($difFiles|Measure-Object).count

    #проверка второго сервера
    $difContents = Get-ChildItem "$mosk_path_two\*$extFile"
    if (($difContents|Measure-Object).count -gt 0){
	    $difFiles_two = Compare-Object -ReferenceObject $refContents -DifferenceObject $difContents -Property ('Name', 'Length') -PassThru |  where-object { $_.SideIndicator -eq '<='} | select Name
    } else {
	    $difFiles_two = $refContents
    }
    $countMsk_two = ($difFiles_two|Measure-Object).count


    #если нет ошибок при копировании переименовываем файлы в *.!* и выходим из скрипта
    if ($countMsk -eq 0 -and $countMsk_two -eq 0){	
	    $files = Get-ChildItem "$maskFiles" -path $pathServer    
    
	    foreach($file1 in $files){		
		    $ext1 = $file1.Extension.substring(2, 2)		
		    $newFile = -join ($file1.BaseName, '.!', $ext1)
		    $msg = Rename-Item $file1.FullName -NewName $newFile -Verbose *>&1
            Write-Log -EntryType Information -Message ($msg | Out-String)
	    }	
	    return 0
    }


    #пишем письмо с ошибкой
    $text1 = ''
    if ($countMsk -gt 0){
	    $text1 = "Файлы не удалось скопировать на $mosk_path`n"
    }

    $text2 = ''
    if ($countMsk_two -gt 0){
	    $text2 = "Файлы не удалось скопировать на $mosk_path_two`n"	
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
}

#основной код программы
Set-Location $dir1
ClearUI
Write-Host -ForegroundColor White "Запуск скрипта..."
Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append


$dir_arr = @($orig_path, $besp_path, $mosk_path, $mosk_path_two)
Test_dir($dir_arr)

$dir_arr = @($log_path, $tmp_path)
Create_dir($dir_arr)

CopyRemote -pathServer $orig_path -maskFiles "a*.0??" -extFile ".xml"
CopyRemote -pathServer $besp_path -maskFiles "b*.0??" -extFile "b.xml"

Write-Host -ForegroundColor White "Конец работы скрипта..."