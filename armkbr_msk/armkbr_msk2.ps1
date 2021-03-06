#программа копирования файлов из кворума на флешку обычных платежей и копирование из в СМЭВ
#переменные

$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#исходный путь
#$orig_path = "m:\cb_out"
$orig_path = "$dir1\cb_out"
#$orig_path = "\\191.168.6.12\quorum\TMN\SENDDOC\CB_OUT_COPY"

#$besp_path = "$dir1\exp"
#$besp_path = "\\191.168.6.12\quorum\TMN\SENDDOC\CB_OUT\BESP\exp"
$besp_path = $orig_path

#путь московсого сервера
#$mosk_path = "\\191.168.7.14\store\СМЭВ\TUMEN\IN"
$mosk_path = "$dir1\test_msk"
#$mosk_path_two = "\\191.168.7.14\store\gis_hcs\TMN\IN"
$mosk_path_two = "$dir1\test_msk_two"

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
	$file2 = -join ($filename.BaseName, '.', $dt, $filename.Extension)	
	return $file2
}

function CopyRemote{    
    Param( 
	    [string]$pathServer,
        [string]$maskFiles
        
    )    
    $extFile = '.xml'
    $errArr = @()

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
        if ($file1.Length -eq 0){
            $message = "Файл $($file1.FullName) нулевой длины!"
            $errArr += $message
            Write-Log -EntryType Error -Message ($message | Out-String)
        }
	    
        #конвертируем имя файла
	    $file21 = fname -filename $file1
        $msg = Rename-Item $file1.FullName -NewName $file21 -Verbose -Force *>&1

        Write-Log -EntryType Information -Message ($msg | Out-String)
    }    
    
    $msg = Copy-Item -Path "$tmp_path\*.xml" -Destination $mosk_path -Verbose -Force *>&1
    Write-Log -EntryType Information -Message ($msg | Out-String)    

    $msg = Copy-Item -Path "$tmp_path\*.xml" -Destination $mosk_path_two -Verbose -Force *>&1
    Write-Log -EntryType Information -Message ($msg | Out-String)

    #Проверка всё ли корректно скопировали
    $refContents = Get-ChildItem "$tmp_path\*$extFile"
    $difContents = Get-ChildItem "$mosk_path\*$extFile"

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

    if ($countMsk -gt 0){
	    $message = "Файлы не удалось скопировать на $mosk_path"
        $errArr += $message
        Write-Log -EntryType Error -Message ($message | Out-String)
    }

    if ($countMsk_two -gt 0){
	    $message = "Файлы не удалось скопировать на $mosk_path_two"	
        $errArr += $message
        Write-Log -EntryType Error -Message ($message | Out-String)
    }

    #если нет ошибок при копировании переименовываем файлы в *.!* и выходим из скрипта
    if ($countMsk -eq 0 -and $countMsk_two -eq 0){	
	    $files = Get-ChildItem "$maskFiles" -path $pathServer    
    
	    foreach($file1 in $files){		
		    $ext1 = $file1.Extension.substring(2, 2)		
		    $newFile = -join ($file1.BaseName, '.!', $ext1)
		    $msg = Rename-Item $file1.FullName -NewName $newFile -Verbose *>&1
            Write-Log -EntryType Information -Message ($msg | Out-String)
	    }		    
    }

    #пишем письмо с ошибкой    
    if ($errArr.count -gt 0){        
        $body = $errArr -join "`n"
        		
        $nowDate = Get-Date
        $subject = "Ошибка при копировании файлов СМЭВ - $nowDate"
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

CopyRemote -pathServer $orig_path -maskFiles "*.xml"

Write-Host -ForegroundColor White "Конец работы скрипта..."