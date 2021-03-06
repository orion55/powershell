$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
[string]$in = "$dir1\in"
#имя лог-файла
[string]$logName = (Get-Item $PSCommandPath ).DirectoryName + "\log\kppClean.log"

. $dir1/script/PSMultiLog.ps1

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
			Write-Host "Путь $d1 не найден!" -ForegroundColor Red
			Write-Host "Нажмите любую клавишу для продолжения" 
			Read-Host "Нажмите Enter"			
			Exit
		}
	}
}

function kppCheck{
	Param( 
	    [string]$fileName
    )    
    Write-Log -EntryType Information -Message "Обработка файла $fileName"
    [xml]$content = Get-Content $fileName    
    $nodes = $content.selectNodes('//РеквПлат[@ИННПП]') | Where-Object { $_.ИННПП.Length -eq 12} |  Where-Object { $_.КПППП -ne $null }    
    
    $count_nodes = ($nodes | Measure-Object).count
    if ($count_nodes -eq 0){
        Write-Log -EntryType Information -Message "Нет найдена информация для корректировки!"
    } else {
        Write-Log -EntryType Information -Message ($nodes | Out-String)
		$nodes | ForEach-Object { $_.RemoveAttribute('КПППП')}
        Write-Log -EntryType Information -Message "КПП удалён"
        $content.Save("$in\$fileName")
    }  
}

ClearUI
Set-Location $in

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

$dir_arr = @($in)
Test_dir($dir_arr)

$bXML = Get-ChildItem -Path $in "B*.xml"
$count_bXML = ($bXML | Measure-Object).count
Write-Log -EntryType Information -Message "Найдено $count_bXML файл(а) в $in!"
if ($count_bXML -eq 0){
    exit
}
Write-Log -EntryType Information -Message ($bXML.Name | Out-String)

foreach ($f in $bXML){
	kppCheck -fileName $f.Name
}

Stop-FileLog
Stop-HostLog