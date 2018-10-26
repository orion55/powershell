#исходный каталог
$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
[string]$symFile = "$curDir\out\ext_op1.out"
[string]$tmpPath = "$curDir\tmp"
[string]$dostowin = "$curDir\util\dostowin.exe"

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
	Clear-Host
}

function testDir($dirList){	
	foreach ($curPath in $dirList){
		#проверка существования путей
		if (!(Test-Path -Path $curPath)){
			Write-Host -ForegroundColor Red "Путь $curPath не найден!"
			Write-Host -ForegroundColor Red "Нажмите любую клавишу для продолжения" 
			Read-Host "Нажмите Enter"			
			Exit
		}
	}
}

function testFiles($filesList){	
	foreach ($curFile in $filesList){
		#проверка существования файлов
		if (!(Test-Path $curFile)){
			Write-Host -ForegroundColor Red "Файл $curFile не найден!"
			Write-Host -ForegroundColor Red "Нажмите любую клавишу для продолжения"  
			Read-Host "Нажмите Enter"			
			Exit
		}
	}
}

function createDir($dirList){	
	foreach ($curPath in $dirList){
		#проверка существования путей
		if (!(Test-Path -Path $curPath)){
			New-Item -ItemType directory -Path $curPath | out-Null
		}
	}
}

Set-Location $curDir

ClearUI

createDir(@($tmpPath))
Remove-Item "$tmpPath\*.*" -recurse | Where { ! $_.PSIsContainer }
testFiles(@($symFile, $dostowin))

Copy-Item $symFile $tmpPath

Write-Host "Конвертируем dos -> win" -ForegroundColor Green
$fileName = Split-Path $symFile -leaf
./util/dostowin.exe "$tmpPath\$fileName" > $null

$fileContent = Get-Content "$tmpPath\$fileName"

[string]$regPattern = '¦[0-9, " "]{2}¦[0-9, " "]{8}¦[0-9, " "]{9}¦[0-9, " "]{20}¦[0-9, ".", " "]{16}¦[0-9, ".", " "]{16}¦.{44}¦'


[int]$maxLine = $fileContent.count
[int]$j = 0
[string]$line = ''
[array]$scroll = @()
$sum = ''

foreach ($curLine in $fileContent)
{		
    if ($curLine -match $regPattern)
    {
        [array]$list = @()
		$list = $curLine.Split("¦")
        #Пустая строка?         
        if ($list[7].Trim() -ne '')
        {
            #Это новая группа, составляющая одну операцию? 
            #$list[2] - Номер документа
            #$list[7] - Назначение операции
            if ($list[2].Trim() -ne '') 
            {
                if ($line.Length -eq 0)
                {
                    $sum = $list[6].Trim()
                    $line = $list[7].Trim()  
                } 
                else
                {
                    $scroll += (@{"sum"=$sum;"desc"=$line})
                    $sum = '';
                    $line = "";
                }
            } 
            else 
            {
                $line += $list[7].Trim()  
            }
        }
    }
    #Write-Progress -Activity $j -PercentComplete ($j / $maxLine * 100) -Status "Фильтрация"
	$j++
}