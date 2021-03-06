param ( 
	[switch]$all = $true	
)

$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
$store = "d:\Ps1\ptk_cover\Store"
$email = @("tmn-goe@tmn.apkbank.ru")

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
	$Host.PrivateData.ProgressForegroundColor = 'Cyan'
	$Host.PrivateData.ProgressBackgroundColor = $bckgrnd
	Clear-Host
}

function Find001([string]$folder){
	if (!(Test-Path $folder)){
		return $null
	}
	$mz = Get-ChildItem "mz*.962.*" -Path $folder
	if ($mz -eq $null){
		return $null
	}	
	$mz01 = Get-ChildItem "mz*.~01.*" -Path $folder
	
	$orig = @()
	foreach ($m in $mz){
		$a = $m.Name.Substring(0, 5)
		$orig += -join($a, "962.~01")
	}
	
	$dest = @()
	foreach ($m1 in $mz01){		
		$dest += $m1.Name.Substring(0, $m1.Name.Length - 7)
	}
	
	$err = @()
	foreach ($o in $orig){
		if ($dest -notcontains $o){
			$err += -join($o.Substring(0, 5), "_01.962")
		}
	}
	return $err	
}

ClearUI

if (!($all)){
	$date1 = Get-Date -UFormat "%Y\%m\%d"
	$rez = Find001("$store\$date1")
	if ($rez -ne $null){
		$encoding = [System.Text.Encoding]::UTF8
		$date2 = Get-Date -UFormat "%d%m%Y"
		$text1 = "Нет подтверждения для посылок в PTK PSD! Скопируйте их во входной каталог UTA повторно!`n"		
		$text1 = -join($text1, "$store\$date1 --> \\tmn-mgmt-03\c`$\UTA\INFO\IN\71svcsdko", $rez | Out-String)
		Write-Host -ForegroundColor Red $text1
		Send-MailMessage -To $email -Body $text1 -Encoding $encoding -From "robot1@tmn.apkbank.apk" -Subject "Нет подтверждения для посылок в PTK PSD $date2" -SmtpServer 191.168.6.50
	}	
} else {
	$tmp_dir = "$dir1\tmp"
	if (!(Test-Path -Path $tmp_dir )){
		New-Item -ItemType directory $tmp_dir -Force | out-null	
	} else {
		Remove-Item $tmp_dir -Force -Recurse
		New-Item -ItemType directory $tmp_dir -Force | out-null	
	}
	
	$folders = Get-ChildItem -Recurse -Path $store | Where-object {!$_.psIsContainer -eq $false} | ForEach-Object -Process {$_.FullName}
	
	foreach ($f in $folders){
		Write-Host -ForegroundColor White $f
		$rez = Find001($f)
		if ($rez -ne $null){
			Write-Host -ForegroundColor DarkCyan $f
			Write-Host -ForegroundColor Cyan $rez | Out-String
			$f | Out-File -Encoding UTF8 -Append -FilePath "error.txt"	
			$rez | Out-String | Out-File -Encoding UTF8 -Append -FilePath "$dir1\error.txt"
			foreach ($r in $rez){
				Copy-Item -Path "$f\$r.*" -Destination $tmp_dir	
			}
		}
	}
}


