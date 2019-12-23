#Программа проверка извещение из ЦБ (версия 2) по формам 440П, 311 для физ. и юр. лиц
#от 17.12.2019

#текущий путь
$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

[string]$lib = "$curDir\lib"
. $curDir/variables.ps1
. $lib/PSMultiLog.ps1
. $lib/libs.ps1

Set-Location $curDir

Clear-Host

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

testDir(@($noticePath))
createDir(@($logPath))
function 440Handler {
	Param($file)

	[hashtable]$return = @{ }
	$return.errFlag = $false
	$return.errType = ''
	$return.errFile = ''
	$return.bodyMail = ''
	$return.type = '440'

	$tmpFile = $file.FullName + '.test'
	$arguments = "-verify -delete -1 -profile $profile -registry -in ""$($file.FullName)"" -out ""$tmpFile"" -silent $logSpki"
	Write-Log -EntryType Information -Message "Обрабатываем файл $($file.Name)"
	Start-Process $spki $arguments -NoNewWindow -Wait

	if (Test-Path $tmpFile) {
		$msg = Remove-Item $($file.FullName) -Verbose -Force *>&1
		Write-Log -EntryType Information -Message ($msg | Out-String)
		$msg = Get-ChildItem $tmpFile | Rename-Item -NewName { $_.Name -replace '.test$', '' } -Verbose *>&1
		Write-Log -EntryType Information -Message ($msg | Out-String)

		$file = Get-ChildItem "$noticePath\$file"
		[xml]$xmlOutput = Get-Content $file

		$xmlTag = $xmlOutput.Файл.ИЗВЦБКОНТР
		if ($xmlTag.КодРезПроверки -ne "01") {
			$return.errFlag = $true
			$return.errType = 'code'
		}
		$msg = 'ИмяФайла: ' + $xmlTag.ИмяФайла + ' Результат: ' + $xmlTag.Пояснение
		$return.bodyMail += $msg + "`r`n"

		if ($xmlTag.КодРезПроверки -ne "01") {
			Write-Log -EntryType Error -Message $msg
		}
		else {
			Write-Log -EntryType Information -Message $msg
		}
	}
	else {
		$msg = "С файла $($file.BaseName) не удалось снять подпись. Осуществите визуальную проверку."
		Write-Log -EntryType Error -Message $msg
		$return.bodyMail += $msg + "`r`n"
		$return.errFlag = $true
		$return.errType = 'file'
	}

	$newName = $file.BaseName + '~' + $file.Extension
	$return.errFile = $noticePath + '\' + $newName
	$msg = Rename-Item $($file.FullName) -NewName $newName -Verbose -Force *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)

	return $return
}
function 311Handler {
	Param($file)

	[hashtable]$return = @{ }
	$return.errFlag = $false
	$return.errType = ''
	$return.errFile = ''
	$return.bodyMail = ''
	$return.type = '311'

	[xml]$content = Get-Content $($file.FullName)
	$rezArh = $content.UV.REZ_ARH

	$msg = 'ИмяФайла: ' + $content.UV.ARH + ' Результат: ' + $rezArh
	$return.bodyMail += $msg + "`r`n"

	if ($rezArh -notlike "принят") {
		$return.errFlag = $true
		$return.errType = 'code'
	}

	if ($return.errFlag) {
		Write-Log -EntryType Error -Message $msg
	}
	else {
		Write-Log -EntryType Information -Message $msg
	}

	$newName = $file.BaseName + '~' + $file.Extension
	$msg = Rename-Item $($file.FullName) -NewName $newName -Verbose -Force *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)

	return $return
}

function sendEmail {
	Param($result)

	$title = "Извещение о проверке файла подтверждения по форме " + $result.type
	if ($result.errFlag -and ($result.errType -eq 'code')) {
		$title = 'Ошибка! ' + $title
	}

	switch ( $result.type ) {
		'440' { $mailAddr = $440mailAddr }
		'311-Физ' { $mailAddr = $311mailAddrFiz }
		'311-Юр' { $mailAddr = $311mailAddrJur }
	}

	Write-Log -EntryType Information -Message "Отправка почтового сообщения"
	if (Test-Connection $mailServer -Quiet -Count 2) {
		$encoding = [System.Text.Encoding]::UTF8
		if ($result.errFlag -and ($result.errType -eq 'file')) {
			Send-MailMessage -To $mailAddr -Body $result.bodyMail -Encoding $encoding -From $mailFrom -Subject $title -SmtpServer $mailServer -Attachments $result.errFile
		}
		else {
			Send-MailMessage -To $mailAddr -Body $result.bodyMail -Encoding $encoding -From $mailFrom -Subject $title -SmtpServer $mailServer
		}
	}
	else {
		Write-Log -EntryType Error -Message "Не удалось соединиться с почтовым сервером $mailServer"
	}
}

if ($debug) {
	Remove-Item -Path "$noticePath\*.*"
	Copy-Item -Path "$curDir\OUT1\*.*" -Destination $noticePath
}

$findFiles = Get-ChildItem -Path $noticePath | Where-Object { ! $_.PSIsContainer } | Where-Object { $_.Name -match $400Mask -or $_.Name -match $311Mask }
$count = ($findFiles | Measure-Object).count

if ($count -eq 0) {
	exit
}
Write-Log -EntryType Information -Message "Начинаем обработку..."
ForEach ($file in $findFiles) {
	if ($file -match $400Mask) {
		$result = 440Handler -file $file
	}
	if ($file -match $311Mask ) {
		$result = 311Handler -file $file
		if ($file -match $311MaskFiz) {
			$result.type = '311-Физ'
		}
		elseif ($file -match $311MaskJur) {
			$result.type = '311-Юр'
		}
	}
	sendEmail -result $result
}

Write-Log -EntryType Information -Message "Завершение обработки..."

Stop-FileLog
Stop-HostLog