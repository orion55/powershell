[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

$orig_dir = "\\191.168.7.14\RBS\TMN\311p"
#$orig_dir = "$curDir\in"

$dest_dir = "\\tmn-ts-01\311p\Arhive"
#$dest_dir = "$curDir\Arhive"

$work_dir = "\\tmn-rkc-01\WORK"
#$work_dir = "$curDir\in\Work"

$post_fix = @("RBS", "WAY4")

Set-Location $curDir

. $curDir/lib/libs.ps1
. $curDir/lib/PSMultiLog.ps1

ClearUI

$rbsOrig = "$orig_dir\RBS"
$way4Orig = "$orig_dir\WAY4"

testDir(@($orig_dir, $rbsOrig, $way4Orig, $dest_dir, $work_dir))
createDir($("$curDir\log"))

$dt = Get-Date -Format "dd-MM-yyyy"
$logName = "$curDir\log\" + $dt + "_LOG.log"

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

$curDate = Get-Date -Format "ddMMyyyy"

$arch_dir = "$dest_dir\$curDate"
if (!(Test-Path -Path $arch_dir )){
	New-Item -ItemType directory $arch_dir -Force | out-null	
}

foreach ($curPrefix in $post_fix){
	$curPrefixDir = "$arch_dir\$curPrefix"
	if (!(Test-Path -Path $curPrefixDir)){
		New-Item -ItemType directory $curPrefixDir -Force | out-null
	}	
}

$rbsArchiv = "$arch_dir\RBS"
$subName = Get-ChildItem "BN*" -Path $rbsOrig -Name -Directory
$countSub = ($subName | Measure-Object).count
if ($countSub -ne 1){
    Write-Log -EntryType Error -Message "Количество вложенных папок в $rbsOrig не равно 1"
}

Write-Log -EntryType Information -Message "Начало копирования файлов..."

$rbsOrigFull = "$rbsOrig\$subName"
$rbsXml = Get-ChildItem -Path $rbsOrigFull "*.xml"
$countRBS = ($rbsXml | Measure-Object).count
if ($countRBS -eq 0){
    Write-Log -EntryType Error -Message "Не найдены файлы в $rbsOrigFull"    
} else {
    try {
        $msg = Copy-Item "$rbsOrigFull\*.xml" -Destination $rbsArchiv -ErrorAction Stop -Verbose -Force *>&1    
        Write-Log -EntryType Information -Message ($msg | Out-String)  
        Write-Log -EntryType Information -Message "Файл(ы) скопирован(ы) в $rbsArchiv"
    }
    catch {    
        Write-Log -EntryType Error -Message "Ошибка копирования файла(ов) в $rbsArchiv"
		Write-Host "Для выхода нажмите любую клавишу"
		$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | out-null
        exit
    }

    try {
        $msg = Copy-Item "$rbsOrigFull\*.xml" -Destination $work_dir -ErrorAction Stop -Verbose -Force *>&1    
        Write-Log -EntryType Information -Message ($msg | Out-String)  
        Write-Log -EntryType Information -Message "Файл(ы) скопирован(ы) в $work_dir"
    }
    catch {    
        Write-Log -EntryType Error -Message "Ошибка копирования файла(ов) в $work_dir"
		Write-Host "Для выхода нажмите любую клавишу"
		$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | out-null
        exit
    }

    try {
        $msg = Remove-Item $rbsOrigFull -ErrorAction Stop -Verbose -Force -Recurse *>&1    
        Write-Log -EntryType Information -Message ($msg | Out-String)  
        Write-Log -EntryType Information -Message "Файл(ы) удален(ы) в $rbsOrigFull"
    }
    catch {    
        Write-Log -EntryType Error -Message "Ошибка удаления файла(ов) в $rbsOrigFull"
		Write-Host "Для выхода нажмите любую клавишу"
		$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | out-null
        exit
    }
}

$way4Archiv = "$arch_dir\WAY4"
$way4Xml = Get-ChildItem -Path $way4Orig "*.xml"
$countWay4 = ($way4Xml | Measure-Object).count
if ($countWay4 -eq 0){
    Write-Log -EntryType Error -Message "Не найдены файлы в $way4Orig"    
} else {
    try {
        $msg = Copy-Item "$way4Orig\*.*" -Destination $way4Archiv -ErrorAction Stop -Verbose -Force *>&1    
        Write-Log -EntryType Information -Message ($msg | Out-String)  
        Write-Log -EntryType Information -Message "Файл(ы) скопирован(ы) в $way4Archiv"
    }
    catch {    
        Write-Log -EntryType Error -Message "Ошибка копирования файла(ов) в $way4Archiv"
		Write-Host "Для выхода нажмите любую клавишу"
		$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | out-null
        exit
    }

    try {
        $msg = Copy-Item "$way4Orig\*.xml" -Destination $work_dir -ErrorAction Stop -Verbose -Force *>&1    
        Write-Log -EntryType Information -Message ($msg | Out-String)  
        Write-Log -EntryType Information -Message "Файл(ы) скопирован(ы) в $work_dir"
    }
    catch {    
        Write-Log -EntryType Error -Message "Ошибка копирования файла(ов) в $work_dir"
		Write-Host "Для выхода нажмите любую клавишу"
		$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | out-null		
        exit
    }

    try {
        $msg = Remove-Item "$way4Orig\*.*" -ErrorAction Stop -Verbose -Force *>&1    
        Write-Log -EntryType Information -Message ($msg | Out-String)  
        Write-Log -EntryType Information -Message "Файл(ы) удален(ы) в $way4Orig"
    }
    catch {    
        Write-Log -EntryType Error -Message "Ошибка удаления файла(ов) в $way4Orig"
		Write-Host "Для выхода нажмите любую клавишу"
		$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | out-null
        exit
    }
}

Stop-FileLog
Stop-HostLog