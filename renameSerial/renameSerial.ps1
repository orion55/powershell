[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
. $curDir/libs/lib.ps1
. $curDir/libs/PSMultiLog.ps1

$inDir = "$curDir\in"
$key = "trnsl.1.1.20160922T080634Z.e3f72af282b6a359.1db854b00bf3418af1ee59dac83d76c7c90fb4b2"
$url = "https://translate.yandex.net/api/v1.5/tr.json"

[string]$logName = (Get-Item $PSCommandPath ).DirectoryName + "\log\serial.log"

function detectLang($newName){
    $params = @{key = $key;text = $newName}
    $request = Invoke-WebRequest "$url/detect" -Method Get -Body $params
    if ($request.StatusCode -eq 200){
        $obj = $request.Content | ConvertFrom-Json
        if ($obj.code -eq 200){
           return $obj.lang
        }
    }
}

function translate(){
    Param(	    
        [string]$lang,
        [string]$text
        )

    $params = @{
        key = $key;
        text = $text;
        lang = "$lang-ru"
    }
    $request = Invoke-WebRequest "$url/translate" -Method Get -Body $params
    if ($request.StatusCode -eq 200){
        $obj = $request.Content | ConvertFrom-Json
        if ($obj.code -eq 200){
           return $obj.text
        }
    }    
}

Set-Location $curDir

ClearUI

testDir(@($inDir))
createDir($("$curDir\log"))

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

$aviFormats = @("*.mkv","*.avi", "*.mp4") 

$fileList = Get-ChildItem -Path $inDir -Directory

#Устраняем многоуровневость папок и удаляем невидео файлы
$tmpDir = "$inDir\tmp"
New-Item -ItemType directory -Path $tmpDir | out-Null

foreach ($file in $fileList){
     #если вложенность папок больше 0
     if ((Get-ChildItem -LiteralPath $file.FullName -Directory -Recurse|Measure-Object).count -gt 0){         
         Get-ChildItem -LiteralPath $file.FullName -File -Recurse | Move-Item -Destination $tmpDir
         Get-ChildItem $tmpDir -Exclude $aviFormats | Remove-item
         Get-ChildItem -LiteralPath $file.FullName -Recurse -Directory | Remove-Item
         Get-ChildItem $tmpDir -File -Recurse | Move-Item -Destination $file.FullName
     }
}

Remove-Item $tmpDir

foreach ($file in $fileList){
    $videoFiles = Get-ChildItem -LiteralPath $file.FullName -File | Where-Object {$_.extension -in ".avi", ".mkv", ".mp4"}
    $videoCount = ($videoFiles | Measure-Object).count
    if ($videoCount -eq 1){
        Move-Item -LiteralPath $videoFiles.FullName -Destination $inDir        
        Write-Log -EntryType Information -Message "Перемещено $videoFiles"
        Remove-Item $file.FullName -Recurse -Force        
        Write-Log -EntryType Warning -Message "Удалено $file"
    }
    if ($videoCount -gt 1){
        foreach ($video in $videoFiles){
            $numberRange = "['s', 'S'](\d{2})['e', 'E'](\d{2})"
            if ($video.name -match $numberRange){
                $i = $Matches[1] 
                $j = $Matches[2]                
                if ($i -eq "01"){
                    $name = "$($video.DirectoryName)\$j$($video.Extension)"                    
                } else {
                    $name = "$($video.DirectoryName)\$i$j$($video.Extension)"
                }
                Rename-Item -LiteralPath $video.FullName -NewName $name                        
            }
        }        
    }
}

$illegalchars2 = [string]::join('',([System.IO.Path]::GetInvalidFileNameChars())) -replace '\\','\\'

$fileList = Get-ChildItem -Path $inDir -Directory
foreach ($file in $fileList){
    $newName = $($file.Name).Replace(".", " ").Replace("_", " ").Replace("[", " ").Replace("]", " ")    
    $lang = detectLang($newName)
    if ($lang -ne "ru"){
        $newName = translate -lang $lang -text $newName
        $newName = $newName -replace "[$illegalchars2]", ''
        $name = "$inDir\$newName"
        Write-Log -EntryType Information -Message "Переименован $($file.FullName) --> $name"
        Rename-Item -LiteralPath $file.FullName -NewName $name
    }    
}

$fileList = Get-ChildItem -Path $inDir -File
foreach ($file in $fileList){
    $year = "['.', '_', '(', ' ']\d{4}['.', '_', ')', ' ']"
    if ($file -match $year){
        $index = $file.Name.IndexOf($Matches[0])
        $newName = $file.Name.Substring(0, $index)
        $newName = $newName.Replace(".", " ").Replace("_", " ")            
        if (!($file -is [System.IO.DirectoryInfo])){            
            $lang = detectLang($newName)
            if ($lang -ne "ru"){
                $newName = translate -lang $lang -text $newName
                $newName = $newName -replace "[$illegalchars2]", ''
            }
            $name = "$($file.DirectoryName)\$newName$($file.Extension)"
            Write-Log -EntryType Information -Message "Переименован $($file.FullName) --> $name"            
            Rename-Item -LiteralPath $file.FullName -NewName $name
        }
    }    
}

Stop-FileLog
Stop-HostLog