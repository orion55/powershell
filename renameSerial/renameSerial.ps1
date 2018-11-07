[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
. $curDir/lib.ps1

$inDir = "$curDir\in"
$key = "trnsl.1.1.20160922T080634Z.e3f72af282b6a359.1db854b00bf3418af1ee59dac83d76c7c90fb4b2"
$url = "https://translate.yandex.net/api/v1.5/tr.json"

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

$fileList = Get-ChildItem -Path $inDir -Directory
foreach ($file in $fileList){    
    $videoFiles = Get-ChildItem $file.FullName -File -Recurse | Where-Object {$_.extension -in ".avi", ".mkv", ".mp4"}
    $videoCount = ($videoFiles | Measure-Object).count
    if ($videoCount -eq 1){
        Move-Item -Path $videoFiles.FullName -Destination $inDir
        Write-Host -ForegroundColor Yellow "Перемещено $videoFiles"
        Remove-Item $file.FullName -Recurse -Force
        Write-Host -ForegroundColor Red "Удалено $file"
    }
    if ($videoCount -gt 1){
        foreach ($video in $videoFiles){
            $numberRange = "['s', 'S'](\d{2})['e', 'E'](\d{2})"
            if ($video.name -match $numberRange){
                $i = $Matches[1] 
                $j = $Matches[2]
                $name = "$($video.DirectoryName)\$i$j$($video.Extension)"                
                Rename-Item -path $video.FullName -NewName $name
            }
        }
    }
}

exit
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
            }
            $name = "$($file.DirectoryName)\$newName$($file.Extension)"
            Write-Host -ForegroundColor Green $name
            Rename-Item -path $file.FullName -NewName $name
        }
    }    
}