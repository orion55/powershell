#Программа для проверки отправленной банковской отчетности по форме 440p
#(c) Гребенёв О.Е. 06.11.2019

[boolean]$debug = $true
[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
[string]$libDir = "$curDir\lib"

. $curDir/variables.ps1
. $libDir/PSMultiLog.ps1
. $libDir/libs.ps1

Set-Location $curDir

#проверяем существуют ли нужные пути и файлы
testDir(@($440Arhive, $outPath))
createDir(@($logDir))

#ClearUI
Clear-Host
Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

Write-Log -EntryType Information -Message "Начало работы скрипта"

[string]$curDate = Get-Date -Format "ddMMyyyy"
[string]$curFormatDate = Get-Date -Format "dd.MM.yyyy"
[string]$curArchive = "$440Arhive\$curDate"

if ($debug) {
    $curDate = '08112019'
    $curFormatDate = '8.11.2019'
    $curArchive = "\\tmn-ts-01\440p\Arhive\$curDate"
    $outPath = "l:\PTK PSD\Post\ELO\OUT\ARCHIV\$curFormatDate"
}

if (!(Test-Path -Path $curArchive)) {
    Write-Log -EntryType Error -Message "Путь $curArchive не найден!"
    exit
}

$body = "Отправлены файлы по 440П за $curFormatDate`n"

$arjFiles = Get-ChildItem -Path $curArchive $outgoingFilesArj
$arjCount = ($arjFiles | Measure-Object).count
$arjArr = @()
$flagErr = $false

if ($arjCount -gt 0) {
    $body += "Архивов было отправлено $arjCount шт.`n"
    ForEach ($file in $arjFiles) {
        $name = $file.Name
        $findFile = Get-ChildItem -Path $outPath | Where-Object { ! $_.PSIsContainer } | Where-Object { $_.Name -match "^IZVTUB_" + $file.BaseName + ".+\.xml$" }
        if (($findFile | Measure-Object).count -eq 1) {
            [string]$xmlDocument = Get-Content $findFile.FullName

            $index = $xmlDocument.IndexOf("</Файл>")
            [xml]$xmlOutput = $xmlDocument.Substring(0, $index + 7)

            $xmlTag = $xmlOutput.Файл.ИЗВЦБКОНТР

            if ($xmlTag.КодРезПроверки -eq "01") {
                $arjArr += , @($name, $xmlTag.Пояснение)
            }
            else {
                $flagErr = $true
                $arjArr += , @($name, "Ошибка: $($xmlTag.Пояснение)")
            }

        }
        else {
            $flagErr = $true
            $arjArr += , @($name, 'Ошибка: На найдено подтверждение о получении архива!')
        }
    }

    $partHtml = ''
    ForEach ($elem in $arjArr) {
        $body += "ИмяФайла: $($elem[0]) Результат: $($elem[1])`n"
        if ($elem[1].Contains("Ошибка")) {
            $partHtml += "<tr><td style=""font-size: 16px; color: red"">ИмяФайла: <strong>$($elem[0])</strong><br>Результат: <strong>$($elem[1])<strong></td></tr>"
        }
        else {
            $partHtml += "<tr><td style=""font-size: 16px"">ИмяФайла: <strong>$($elem[0])</strong><br>Результат: <strong>$($elem[1])<strong></td></tr>"
        }

    }
}
else {
    Write-Log -EntryType Error -Message "Архивы в каталоге $curArchive не найдены!"
    exit
}

$xmlFiles = Get-ChildItem -Path $curArchive $outgoingFilesXml
$xmlCount = ($xmlFiles | Measure-Object).count

if ($xmlCount -gt 0) {
    $body += "Файлов было отправлено $xmlCount шт.`n"
}

$bodyHtml = @"
<table>
    <tr>
        <td style="text-align: center; font-size: 22px">Отправлены файлы по 440П за $curFormatDate</td>
    </tr>
    <tr>
        <td style="padding-left: 10px; padding-right: 10px"><hr></td>
    </tr>
    <tr>
        <td style="text-align: center; font-size: 18px">Архивов было отправлено <strong>$arjCount</strong> шт.</td>
    </tr>
    $partHtml
    <tr>
        <td style="padding-left: 10px; padding-right: 10px"><hr></td>
    </tr>
    <tr>
        <td style="text-align: center; font-size: 18px">Файлов было отправлено <strong>$xmlCount</strong> шт.</td>
    </tr>
</table>
"@

if (Test-Connection $mailServer -Quiet -Count 2) {
    $title = "Отправленные сообщения: содержащее запросы по 440-П за $curFormatDate"
    if ($flagErr) {
        $title = "Ошибка! " + $title
    }
    $encoding = [System.Text.Encoding]::UTF8
    Send-MailMessage -To $mailAddr -Body $bodyHtml -Encoding $encoding -From $mailFrom -Subject $title -SmtpServer $mailServer -BodyAsHtml
}
else {
    Write-Log -EntryType Error -Message "Не удалось соединиться с почтовым сервером $mail_server"
}

Write-Log -EntryType Information -Message $body

Stop-FileLog
Stop-HostLog