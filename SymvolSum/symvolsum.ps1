#исходный каталог
$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
[string]$symFile = "$curDir\out\ext_op1.out"
[string]$tmpPath = "$curDir\tmp"
[string]$resultPath = "$curDir\result"
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

createDir(@($tmpPath, $resultPath))
Remove-Item "$tmpPath\*.*" -recurse | Where { ! $_.PSIsContainer }
testFiles(@($symFile, $dostowin))

Copy-Item $symFile $tmpPath

Write-Host "Конвертируем dos -> win" -ForegroundColor Green
$fileName = Split-Path $symFile -leaf
./util/dostowin.exe "$tmpPath\$fileName" > $null

$fileContent = Get-Content "$tmpPath\$fileName"

#[string]$regPattern = '¦[0-9, " "]{2}¦[0-9, " "]{8}¦[0-9, " "]{9}¦[0-9, " "]{20}¦[0-9, ".", " "]{16}¦[0-9, ".", " "]{16}¦.{44}¦'
[string]$regPattern = '¦[0-9, "."]{8}¦[0-9, " "]{2}¦[0-9, " "]{8}¦[0-9, " "]{9}¦[0-9, " "]{20}¦[0-9, ".", " "]{16}¦[0-9, ".", " "]{16}¦.{35}¦'

[int]$maxLine = $fileContent.count
[int]$j = 0
[string]$line = ''
[array]$scroll = @()
$sum = 0

Write-Host -ForegroundColor Green "Фильтрация"

foreach ($curLine in $fileContent)
{		
    if ($curLine -match $regPattern)
    {
        [array]$list = @()
		$list = $curLine.Split("¦")
        #Пустая строка?         
        if ($list[8].Trim() -ne '')
        {
            #Это новая группа, составляющая одну операцию? 
            #$list[3] - Номер документа
            #$list[8] - Назначение операции
            if ($list[3].Trim() -ne '') 
            {
                if ($line.Length -eq 0)
                {
                    $sum = +$list[7].Trim()
                    $line = $list[8].Trim()  
                } 
                else
                {
                    $scroll += (@{"sum"=$sum;"desc"=$line})
                    $sum = +$list[7].Trim();
                    $line = $list[8].Trim();
                }
            } 
            else 
            {
                $line += $list[8].Trim()  
            }
        }
    }
    Write-Progress -Activity $j -PercentComplete ($j / $maxLine * 100) -Status "Фильтрация"
	$j++
}

if ($scroll.Length -eq 0)
{
    exit
}
$scroll += (@{"sum"=$sum;"desc"=$line})

$symvol = @{}
[string]$pattern = "Назначение):"
[int]$lenPattern = $pattern.Length

foreach ($curElement in $scroll)
{
    if ($curElement.sum -ne 0)
    {
        [string]$desc = $curElement.desc
        $ind = $desc.IndexOf($pattern)
        if ($ind -ne -1)
        {
            [int]$index = $desc.IndexOf($pattern) + $lenPattern
            [string]$subString = $desc.Substring($index, $desc.Length - $index)
            $sym = $subString.Substring(0, 3)
            $symvol[$sym] += $curElement.sum            
            $symvol[$($sym +'_count')] += 1
        }
    }
}

Write-Host -ForegroundColor Green "Результат"
$text = $symvol.GetEnumerator() | sort -Property name
if ($text.Length -ne 0)
{
    $text
    $text | Out-File -Encoding utf8 "$resultPath\result.txt"
}