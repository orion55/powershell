#Программа для автоматизации отправки банковской отчетности по форме 440п
Param(
  [switch]$autoget = $false
)

[string]$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
[string]$lib = "$dir1\lib"

. $dir1/variables.ps1
. $lib/PSMultiLog.ps1
. $lib/libs.ps1
. $lib/libsVerba.ps1

$global:incoming_files_arj = $null
Import-Module PSSQLite

Set-Location $dir1

ClearUI

Start-HostLog -LogLevel Information

$curDate = Get-Date -Format "ddMMyyyy"
[string]$logName440 = (Get-Item $PSCommandPath ).DirectoryName + "\log\" + $curDate +"_f440.log"

Start-FileLog -LogLevel Information -FilePath $logName440 -Append

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
$dir_arr = @($work, $scripts, $disk_sig, , $disk_sig_send, $disk_crypt, $arm440, $incoming_out, $comita_in, $arm440_ul, $arm440_fl)
Test_dir($dir_arr)

$files_arr = @($script_sig, $script_unsig, $script_crypt, $script_uncrypt, $verba, $arj32)
Test_files($files_arr)

#копируем файлы отчетности в каталог $work
if (!($nobegin)){
	switch ($form){ 
	 	'440in' {
			Remove-Item -Path "$work\*.*"
			
            $global:incoming_files_arj= Get-ChildItem -Path $incoming_out $incoming_files
			if ($global:incoming_files_arj.count -eq 0){
				exit
			}
            
            Check-FilesLock -in_files $global:incoming_files_arj
			
            foreach ($f2 in $global:incoming_files_arj){												
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
} else {
    $files2 = Get-ChildItem -Path $work "*.xml"
	if ($files2.count -eq 0){
        Write-Log -EntryType Error -Message "Файлы xml в каталоге $work не найдены!"
	    exit
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
        
		foreach ($f2 in $global:incoming_files_arj){												
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