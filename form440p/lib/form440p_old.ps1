#Программа для автоматизации отправки банковской отчетности по форме 440п
Param(
  [switch]$autoget = $false
)

[string]$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
. $dir1/variables.ps1
. $dir1/PSMultiLog.ps1

Set-Location $dir1

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

function Test_files($files){	
	foreach ($f1 in $files){
		#проверка существования файлов
		if (!(Test-Path $f1)){
			Write-Log -EntryType Error -Message "Файл $f1 не найден!"
			Write-Log -EntryType Information -Message "Нажмите любую клавишу для продолжения" 
			Read-Host "Нажмите Enter"			
			Exit
		}
	}
}

function Verba_script{
	Param( 
		[String]$scrpt_name,
		[String]$mask = "*.*")
	
	    [string]$tmp = "$dir1\tmp"
        [int]$amount =3
	
	do{
		$ht = @()
		Get-ChildItem "$work\$mask" | %{ $ht += ,($_.Name, $_.Length)}
		
		Write-Log -EntryType Information -Message "Начинаем преобразование..."
		Start-Process "$verba" "/@$scrpt_name" -NoNewWindow -Wait
		Start-Sleep -Seconds 3
		
		#проверяем действительно или все файлы подписаны\расшифрованы. Верба иногда вылетает с ошибкой.
		$ff = Get-ChildItem "$work\$mask"
		Write-Log -EntryType Information -Message "Сравниваем до и после преобразования..."
		foreach ($f1 in $ff){	
			$ht |  % {$i = 0} { if ($_ -eq $f1.Name) {$ht[$i] += $f1.Length}; $i++} {}	
		}
		$not_diff = @()
		foreach ($h1 in $ht){
			if ($h1[1] -eq $h1[2]){
				$not_diff += [string]$h1[0]		
			}
		}
		#если не все преобразованы, повторяем процесс
		$count = ($not_diff | Measure-Object).count
		if ($count -ne 0){
			
			Write-Log -EntryType Error -Message "Часть файлов не были преобразованы!"
						
			if (!(Test-Path $tmp)){
				New-Item -ItemType directory -Path $tmp | out-Null
			}
			$files1 = Get-ChildItem "$work\$mask" |  Select-Object Name | ? {$not_diff -notcontains $_.Name} | % {$_.Name}
			foreach ($ff2 in $files1){
				Move-Item -Path "$work\$ff2" -Destination $tmp
			}
			
		}
        $amount--
	} until ($count -eq 0 -or $amount -eq 0)
    	
	if (Test-Path $tmp){
		Move-Item -Path "$tmp\*.*" -Destination $work
		Remove-Item -Recurse $tmp
	}
    
    if ($amount -eq 0){
        Write-Log -EntryType Error -Message "Ошибка при работе с Verba"
        exit
    }
	Start-Sleep -Seconds 5
}

#копируем каталоги рекурсивно на "волшебный" диск А: - туда и обратно
function Copy_dirs{
	Param( 
	[string]$from,
	[string]$to)
	
	Get-ChildItem -Path $from -Recurse  | 
    Copy-Item -Destination {
        if ($_.PSIsContainer) {
            Join-Path $to $_.Parent.FullName.Substring($from.length)
        } else {
            Join-Path $to $_.FullName.Substring($from.length)
        }
    } -Force
}

function kwtfcbCheck{
	$kwtFiles = Get-ChildItem "$work\KWTFCB_*.xml"	
	if ($kwtFiles.count -eq 0){
		return
	}
	$errorArr = @()
	$successArr = @()
	$flag = $true
	foreach ($kwt in $kwtFiles){														
		[xml]$xml = Get-Content $kwt
		$result = $xml.Файл.КВТНОПРИНТ.Результат
		if (!$result){
			$result = $xml.Файл.КВТНОПРИНТ
			if (!$result){
				$flag = $false
			}
		} elseif ($result.КодРезПроверки -ne "01") {
			$flag = $false
		} 
		
		if ($flag){
			$successArr += $kwt.Name
		} else{
			$errorArr += $kwt.Name
		}
        $flag = $true
	}
	
	$curDate = Get-Date -Format "ddMMyyyy"
	$body = ""
	$title = ""
	
	if ($successArr.Count -ne 0){
		$succPath = $440p_ack + '\' + $curDate		
		if (!(Test-Path $succPath)){
			New-Item -ItemType directory -Path $succPath | out-Null
		}
		Write-Log -EntryType Information -Message "Пришли подтверждения"
		foreach ($file in $successArr){			
			Copy-Item -Path "$work\$file" -Destination $succPath -ErrorAction "SilentlyContinue"
		}		
		$count = $successArr.Count
		$body += "Пришли успешные подтверждения - $count шт.`n"		
		$body += "Потверждения находятся в каталоге $succPath`n"
		$body += "`n"
		$title = "Пришли подтверждения по 440П"
	}
	
	if ($errorArr.Count -ne 0){		
		$errPath = $440p_err + '\' + $curDate		
		if (!(Test-Path $errPath)){
			New-Item -ItemType directory -Path $errPath | out-Null
		}
		Write-Log -EntryType Error -Message "Пришли подтверждения с ошибками!"
		foreach ($file in $errorArr){
			Copy-Item -Path "$work\$file" -Destination $errPath -ErrorAction "SilentlyContinue"
		}
		$count = $errorArr.Count
		$body += "Пришли подтверждения с ошибками - $count шт.`n"		
		$body += $errorArr -join "`n"
		$body += "`n"
		$body += "Потверждения находятся в каталоге $errPath`n"
		$title = "Пришли подтверждения с ошибками по 440П"
	}
	
	$encoding = [System.Text.Encoding]::UTF8
	Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
    Write-Log -EntryType Information -Message $body
	
    Copy-Item -Path "$work\KWTFCB_*.xml" -Destination $arm440 -ErrorAction "SilentlyContinue"
    Copy-Item -Path "$work\KWTFCB_*.xml" -Destination $comita_in -ErrorAction "SilentlyContinue"
	Remove-Item -Path "$work\KWTFCB_*.xml"
}

function documentsCheck{
	$docFiles = Get-ChildItem "$work\*.xml"
	if ($docFiles.count -eq 0){
		return
	}
	$typeDocs = @{resolution = 0; charge = 0; request = 0; demand = 0; other = 0}
	$resolution = 'RPO', 'ROO', 'APN', 'APO', 'APZ'
	$charge = 'PNO', 'PPD', 'PKO'
	$request = 'ZSN', 'ZSO', 'ZSV'
	$demand = 'TRB', 'TRG'
	
	foreach ($file in $docFiles){
		$firstChars = $file.BaseName.Substring(0, 3)		
		if ($resolution -contains $firstChars){
			$typeDocs.resolution++
		} elseif ($charge -contains $firstChars){
			$typeDocs.charge++
		} elseif ($request -contains $firstChars){
			$typeDocs.request++
		} elseif ($demand -contains $firstChars){
			$typeDocs.demand++
		} else {
			$typeDocs.other++
		}
	}
	
	$title = "Пришли сообщения по 440П"
	$count = $docFiles.count
	$body = "Пришло всего $count сообщений`n"
	$body += "Из них:`n"	
	
	if ($typeDocs.resolution -gt 0){
		$body += "Решения: " + $typeDocs.resolution + "`n"
	}
	if ($typeDocs.charge -gt 0){
		$body += "Поручения: " + $typeDocs.charge + "`n"
	}
	if ($typeDocs.request -gt 0){
		$body += "Запросы: " + $typeDocs.request + "`n"		
	}
	if ($typeDocs.demand -gt 0){
		$body += "Требования: " + $typeDocs.demand + "`n"		
	}
	if ($typeDocs.other -gt 0){
		$body += "Прочие документы: " + $typeDocs.other + "`n"
	}		
	
	$encoding = [System.Text.Encoding]::UTF8
	Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
    Write-Log -EntryType Information -Message $body
	
	$curDate = Get-Date -Format "ddMMyyyy"
	$arhivePath = $440p_arhive + '\' + $curDate
	if (!(Test-Path $arhivePath)){
			New-Item -ItemType directory -Path $arhivePath | out-Null
	}
	Copy-Item -Path "$work\*.xml" -Destination $arhivePath -ErrorAction "SilentlyContinue"
	Copy-Item -Path "$work\*.xml" -Destination $arm440 -ErrorAction "SilentlyContinue"
    Copy-Item -Path "$work\*.xml" -Destination $comita_in -ErrorAction "SilentlyContinue"
	Remove-Item -Path "$work\*.xml"
}

function 440_in{
    $curDate = Get-Date -Format "ddMMyyyy"
	$arhivePath = $440p_arhive + '\' + $curDate
	if (!(Test-Path $arhivePath)){
		New-Item -ItemType directory -Path $arhivePath | out-Null
	}
		
	#переносим файлы в архив
	Write-Log -EntryType Information -Message "Переносим файлы в архив $arhivePath"
	Copy-Item -Path "$work\*.arj" -Destination $arhivePath
		
	#снимаем подпись с отчетов
	Write-Log -EntryType Information -Message "Снимаем подпись с arj-архивов"
	Write-Log -EntryType Information -Message "Загружаем ключевую дискету $disk_sig"
	Copy_dirs -from $disk_sig -to 'a:'		
	Verba_script -scrpt_name $script_unsig -mask "*.arj"
		
	Set-Location $work
		
	Write-Log -EntryType Information -Message "Начинаем разархивацию..."
	$AllArgs = @('e', '-y', '*.arj')
	&$arj32	$AllArgs
		
	Remove-Item -Path '*.arj'
		
	$vrbFiles = Get-ChildItem "$work\*.vrb"
	if ($vrbFiles.count -gt 0){
		#расшифровываем файлы
		Write-Log -EntryType Information -Message "Расшифровываем vrb-файлы"
		Write-Log -EntryType Information -Message "Загружаем ключевую дискету $disk_crypt"
		Remove-Item 'a:' -Recurse -ErrorAction "SilentlyContinue"
		Copy_dirs -from $disk_crypt -to 'a:'		
		Verba_script -scrpt_name $script_uncrypt -mask "*.VRB"
			
		Write-Log -EntryType Information -Message "Переименовываем файлы в xml"
		Get-ChildItem '*.vrb' | Rename-Item -NewName { $_.Name -replace '.vrb$','.xml' }		
	}
		
	#снимаем подпись с xml-файлов
	Write-Log -EntryType Information -Message "Снимаем подпись с xml-файлов"
	Write-Log -EntryType Information -Message "Загружаем ключевую дискету $disk_sig"
	Remove-Item 'a:' -Recurse -ErrorAction "SilentlyContinue"
	Copy_dirs -from $disk_sig -to 'a:'
	Verba_script -scrpt_name $script_unsig -mask "*.xml"
		
	Write-Log -EntryType Information -Message "Форматируем xml-файлы"
	$files_xml = Get-ChildItem -Path "*.xml"			
	foreach ($file_xml in $files_xml){
		[xml]$xml = Get-Content $file_xml
		$xml.Save($file_xml)
	}
}

Function Validate-Xml{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$xmlFileName,
        
        [Parameter(Mandatory=$True)]
        [string]$xsdFileName
    )

    # Check if the provided file exists
    if(!(Test-Path -Path $xmlFileName))
    {
        Write-Log -EntryType Error -Message "Проверка XML невозможна, поскольку не найден XML-файл в '$xmlFileName'"
        exit 2
    }

    # Check if the provided file exists
    if(!(Test-Path -Path $xsdFileName))
    {
        Write-Log -EntryType Error -Message "Проверка XML невозможна, поскольку XSD-файл не найден '$xsdFileName'"
        exit 3
    }

    #making the schemaset
    $schemaSet = New-Object -TypeName System.Xml.Schema.XmlSchemaSet
    [void]$schemaSet.Add("", $xsdFileName)
    $compiledSchema = $null
    Foreach($schema in $schemaSet)
    {
	    $compiledSchema = $schema
    }

    # Get the file
    $XmlFile = Get-Item($xmlFileName)

    # Keep count of how many errors there are in the XML file
    $script:errorCount = 0

    # Perform the XSD Validation
    $readerSettings = New-Object -TypeName System.Xml.XmlReaderSettings
    $readerSettings.Schemas.Add($compiledSchema)
    $readerSettings.ValidationType = [System.Xml.ValidationType]::Schema
    $readerSettings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessInlineSchema -bor [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessSchemaLocation
    $readerSettings.add_ValidationEventHandler(
    {
        # Triggered each time an error is found in the XML file
        Write-Log -EntryType Error -Message $("Ошибка в XML: " + $_.Message)
        $script:errorCount++
    });
    $reader = [System.Xml.XmlReader]::Create($XmlFile.FullName, $readerSettings)
    while ($reader.Read()) { }
    $reader.Close()

    # Verify the results of the XSD validation
    if($script:errorCount -gt 0)
    {
        # XML is NOT valid
        return 1
    }
    else
    {
        # XML is valid
        return 0
    }
}

Function Validate-Catalog{
    $m = Get-ChildItem "$work\*.xml" | measure    
    if ($m.count -eq 0){
        Write-Log -EntryType Error -Message "XML-файлы не найденны"
        exit        
    }
    
    $xmlFiles = Get-ChildItem "$work\*.xml"
    [bool]$flag_err = $false
    
    foreach ($xmlFile in $xmlFiles){
        $name3Char = $xmlFile.BaseName.Substring(0, 3)
        $name2Char = $xmlFile.BaseName.Substring(0, 2)
        
        if ($name2Char -eq "PB"){
            $name3Char = "PBQ"
        }
        $xsdName = $name3Char + "_300.xsd"
        $xsdFile = $schemaCatalog + "\" + $xsdName        
        
        if(!(Test-Path -Path $xsdFile)){
            Write-Log -EntryType Error -Message "Файл XSD-схемы не найден $xsdName"
        } else {
            $valid = Validate-Xml -xmlFileName $xmlFile -xsdFileName $xsdFile
            if ($valid -eq 0){
                Write-Log -EntryType Information -Message "Валидация файла прошла успешно $xmlFile"
            } else {
                Write-Log -EntryType Error -Message "Ошибка валидации файла $xmlFile"
                $flag_err = $true
            }
        }
    }

    return $flag_err
}

function documentsCheckSend{
    $docFiles = Get-ChildItem "$work\*.xml"
	if ($docFiles.count -eq 0){
		return
	}
	$typeDocs = @{message = 0; ref = 0; notice = 0; info = 0; extract = 0; query = 0; confirmation = 0; other = 0}
	[string]$message = 'BNP'
	$ref = 'BNS', 'BOS'
    [string]$notice = 'BUV'
	[string]$info = 'BVD'
	[string]$extract = 'BVS'
    [string]$query = 'BZ1'
    [string]$confirmation = 'PB'
	
	foreach ($file in $docFiles){
		$firstChars = $file.BaseName.Substring(0, 3)
        $firstChars2 = $file.BaseName.Substring(0, 2)
		if ($message -contains $firstChars){
			$typeDocs.message++
		} elseif ($ref -contains $firstChars){
			$typeDocs.ref++
		} elseif ($notice -contains $firstChars){
			$typeDocs.notice++
		} elseif ($info -contains $firstChars){
			$typeDocs.info++
        } elseif ($extract -contains $firstChars){
			$typeDocs.extract++
        } elseif ($query -contains $firstChars){
			$typeDocs.query++
        } elseif ($confirmation -contains $firstChars2){
			$typeDocs.confirmation++
		} else {
			$typeDocs.other++
		}
	}
    
#    $title = "Отправлены сообщения по 440П"
	$count = $docFiles.count
	$body = "Отправленно всего $count сообщений`n"
	$body += "Из них:`n"	
	
	if ($typeDocs.message -gt 0){
		$body += "Сообщения: " + $typeDocs.message + "`n"
	}
	if ($typeDocs.ref -gt 0){
		$body += "Справка: " + $typeDocs.ref + "`n"
	}
	if ($typeDocs.notice -gt 0){
		$body += "Уведомления: " + $typeDocs.notice + "`n"		
	}
	if ($typeDocs.info -gt 0){
		$body += "Сведения: " + $typeDocs.info + "`n"		
	}
    if ($typeDocs.extract -gt 0){
		$body += "Выписка: " + $typeDocs.extract + "`n"		
	}
    if ($typeDocs.query -gt 0){
		$body += "Запрос: " + $typeDocs.query + "`n"
	}
    if ($typeDocs.confirmation -gt 0){
		$body += "Потверждения: " + $typeDocs.confirmation + "`n"		
	}
	if ($typeDocs.other -gt 0){
		$body += "Прочие документы: " + $typeDocs.other + "`n"
	}		
	
#	$encoding = [System.Text.Encoding]::UTF8
#	Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
#   Write-Log -EntryType Information -Message $body
    return $body
}

Function 440_out{
    #проверяем на соотвествие XSD - формата
    if (Validate-Catalog){
        $title = "Ошибка валидации"
        $message = "При валидации произошла ошибка. Продлжить отправку отчетности?"
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "Да - &0", "Да"
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "Нет - &1", "Нет"
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        try {
	        $choice = $host.ui.PromptForChoice($title, $message, $options, 1)
	        switch ($choice){
		        0  { $proceed = $true}
		        1  { $proceed = $false}
	        }	
        }
        catch [Management.Automation.Host.PromptingException] {
	        Write-Log -EntryType Warning -Message "Выход!"
            exit
        }
        if (!$proceed){
            return
        }
    }
    #проверяем типы сообщений для отправки
    [string]$body = documentsCheckSend

    $curDate = Get-Date -Format "ddMMyyyy"
	$arhivePath = $440p_arhive + '\' + $curDate
	if (!(Test-Path $arhivePath)){
			New-Item -ItemType directory -Path $arhivePath | out-Null
	}
    
    Stop-HostLog
	$msg = Copy-Item -Path "$work\*.xml" -Destination $arhivePath -Verbose -Force *>&1
    Write-Log -EntryType Information -Message ($msg | Out-String)    
    Start-HostLog -LogLevel Information
    Write-Log -EntryType Information -Message "Копирование файлов в архив $arhivePath"

    Write-Log -EntryType Information -Message "Переименовываем файлы *.xml -> *.vrb"
    Get-ChildItem "$work\b*.xml" -Exclude "$work\bz1*.xml" | rename-item -newname { $_.name -replace '\.xml','.vrb' }

    #подписываем все файлы
	Write-Log -EntryType Information -Message "Подписываем все файлы"
	Write-Log -EntryType Information -Message "Загружаем ключевую дискету $disk_sig_send"
	Copy_dirs -from $disk_sig_send -to 'a:'		
	Verba_script -scrpt_name $script_sig -mask "*.*"

    $vrbFiles = Get-ChildItem "$work\*.vrb"
	if ($vrbFiles.count -gt 0){        
		#зашифровываем файлы
		Write-Log -EntryType Information -Message "Зашифровываем vrb-файлы"
		Write-Log -EntryType Information -Message "Загружаем ключевую дискету $disk_crypt"
		Remove-Item 'a:' -Recurse -ErrorAction "SilentlyContinue"
		Copy_dirs -from $disk_crypt -to 'a:'		
		Verba_script -scrpt_name $script_crypt -mask "*.vrb"
	}
    
    $afnFiles = Get-ChildItem "$arhivePath\AFN_7106962_MIFNS00_*.arj"
    $afnCount = ($afnFiles | Measure-Object).count
    $afnCount++
    $afnCountStr = $afnCount.ToString("00000")
    
    $curDateAfn = Get-Date -Format "yyyyMMdd"
    $afnFileName = "AFN_7106962_MIFNS00_" + $curDateAfn + "_" + $afnCountStr + ".arj"

    Write-Log -EntryType Information -Message "Начинаем архивацию..."
	$AllArgs = @('a', '-e', "$work\$afnFileName", "$work\*.xml", "$work\*.vrb")
	&$arj32	$AllArgs
    
    Remove-Item "$work\*.*" -Exclude "AFN_7106962_MIFNS00_*.arj"

    #подписываем все файлы
	Write-Log -EntryType Information -Message "Подписываем файл архива $work\$afnFileName"
	Write-Log -EntryType Information -Message "Загружаем ключевую дискету $disk_sig_send"
	Copy_dirs -from $disk_sig_send -to 'a:'		
	Verba_script -scrpt_name $script_sig -mask "*.arj"

    Write-Log -EntryType Information -Message "Копируем файл архива $afnFileName в $arhivePath"
    Copy-Item "$work\$afnFileName" -Destination $arhivePath -Force
    Write-Log -EntryType Information -Message "Копируем файл архива $afnFileName в $outcoming_post"
    Copy-Item "$work\$afnFileName" -Destination $outcoming_post -Force

    Remove-Item "$work\$afnFileName"

    $title = "Отправлены сообщения по 440П"
	$encoding = [System.Text.Encoding]::UTF8
	Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
    Write-Log -EntryType Information -Message $body
}

ClearUI

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

if (!$autoget){
    #меню для ввода с клавиатуры
    $title = "Отправка отчетности по форме 440п"
    $message = "Выберите вариант для отправки отчетности:"
    $440in = New-Object System.Management.Automation.Host.ChoiceDescription "440п принять - &0", "440in"
    $440out = New-Object System.Management.Automation.Host.ChoiceDescription "440п отправить - &1", "440out"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($440in, $440out)
    try {
	    $choice = $host.ui.PromptForChoice($title, $message, $options, 0)
	    switch ($choice){
		    0  { $form = "440in"}
		    1  { $form = "440out"}			
	    }
    }
    catch [Management.Automation.Host.PromptingException] {
	    Write-Log -EntryType Warning -Message "Выход!"
        exit
    }

    $title = "Автоматизация копирования"
    $message = "Файлы отчетности скопированы в папку $work ?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "Да - &0", "Да"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "Нет - &1", "Нет"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    try {
	    $choice = $host.ui.PromptForChoice($title, $message, $options, 1)
	    switch ($choice){
		    0  { $nobegin = $true}
		    1  { $nobegin = $false}
	    }	
    }
    catch [Management.Automation.Host.PromptingException] {
	    Write-Log -EntryType Warning -Message "Выход!"
        exit
    }

    Write-Log -EntryType Information -Message "Обработка отчетности - $form"

    if ($nobegin){
	    Write-Log -EntryType Warning -Message "Автоматическое копирование в папку $work произведено не было!"
    }
} else {
    #автоматический режим
    Write-Log -EntryType Information -Message "Автоматический режим работы"
    $files2 = Get-ChildItem -Path $incoming_out $incoming_files
	if ($files2.count -eq 0){
        Write-Log -EntryType Information -Message "Файлы отчетности не найдены в каталоге $incoming_out"
		exit
	}
    $files3 = Get-ChildItem -Path $work -File *.*
	if ($files3.count -gt 0){
        Write-Log -EntryType Information -Message "Найдены файлы в каталоге $work"
		exit
	}
    
    $encoding = [System.Text.Encoding]::UTF8
    $date = Get-Date -UFormat "%d.%m.%Y %H:%M:%S"
    $title = "Автоматический приём по форме 440П"
    $body = "Начат автоматический приём по форме 440П $date"
	Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
    Write-Log -EntryType Information -Message $body
    $nobegin = $false
    $form = "440in"
}

#проверяем существуют ли нужные пути и файлы
$dir_arr = @($work, $scripts, $disk_sig, , $disk_sig_send, $disk_crypt, $arm440, $incoming_out, $comita_in, $arm440_ul, $arm440_fl, $schemaCatalog)
Test_dir($dir_arr)

$files_arr = @($script_sig, $script_unsig, $script_crypt, $script_uncrypt, $verba, $arj32)
Test_files($files_arr)

#копируем файлы отчетности в каталог $work
if (!($nobegin)){
	switch ($form){ 
	 	'440in' {
			Remove-Item -Path "$work\*.*"
			$files2 = Get-ChildItem -Path $incoming_out $incoming_files
			if ($files2.count -eq 0){
				exit
			}
			foreach ($f2 in $files2){												
				Copy-Item -Path "$incoming_out\$f2" -Destination $work
				Write-Log -EntryType Information -Message "Копируем файл $f2"				
			}
		}
        '440out' {
            Remove-Item -Path "$work\*.*"
            $files2 = Get-ChildItem -Path $arm440_ul "*.xml"
			if ($files2.count -eq 0){
				exit
			}
            $msg = Move-Item -Path "$arm440_ul\*.xml" -Destination $work -Verbose -Force *>&1
            Write-Log -EntryType Information -Message ($msg | Out-String)
            
            $files2 = Get-ChildItem -Path $arm440_fl "*.xml"
			if ($files2.count -gt 0){
				$msg = Move-Item -Path "$arm440_ul\*.xml" -Destination $work -Verbose -Force *>&1
                Write-Log -EntryType Information -Message ($msg | Out-String)
			}                                    
        }
	    default {exit}
	}
}

#проверяем есть ли диск А
$disks = (Get-PSDrive -PSProvider FileSystem).Name
if ($disks -notcontains "a"){
	Write-Log -EntryType Error -Message "Диск А не найден!"
	exit
}

#сохраняем текущею ключевую дискету
Write-Log -EntryType Information -Message "Сохраняем текущею ключевую дискету"
$tmp_keys = "$dir1\tmp_keys"
if (!(Test-Path $tmp_keys)){
	New-Item -ItemType directory -Path $tmp_keys | out-Null
}
Copy_dirs -from 'a:' -to $tmp_keys
Remove-Item 'a:' -Recurse -ErrorAction "SilentlyContinue"

switch ($form){ 
	 '440in' {
	 	440_in		
		kwtfcbCheck
		documentsCheck        
        
        $files2 = Get-ChildItem -Path $incoming_out $incoming_files
		if ($files2.count -eq 0){
			exit
		}
		foreach ($f2 in $files2){												
			Remove-Item -Path "$incoming_out\$f2"
			Write-Log -EntryType Information -Message "Удаляем файл $incoming_out\$f2"				
		}
	}
    '440out'{
        440_out   
    }
	default {exit}
}

Write-Log -EntryType Information -Message "Загружаем исходную ключевую дискету"
Remove-Item 'a:' -Recurse -ErrorAction "SilentlyContinue"
Copy_dirs -from $tmp_keys -to 'a:'
Remove-Item $tmp_keys -Recurse

Write-Log -EntryType Information -Message "Конец работы скрипта!"

Stop-FileLog
Stop-HostLog