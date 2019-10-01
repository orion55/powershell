#исходный каталог
$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
[string]$inFile = "$curDir\in\buxjur.out"
[string]$tmpPath = "$curDir\tmp"
[string]$outPath = "$curDir\out"
$curDate = Get-Date -Format "ddMMyyyy"
[string]$outFile = "$curDir\out\buxjur" + $curDate + ".xlsx"
[string]$dostowin = "$curDir\lib\dostowin.exe"

. $curDir/lib/libs.ps1

Set-Location $curDir

ClearUI

createDir(@($tmpPath, $outPath))
Remove-Item "$tmpPath\*.*" -recurse | Where { ! $_.PSIsContainer }
testFiles(@($inFile, $dostowin))

Remove-Item $outFile -ErrorAction Ignore

Copy-Item $inFile $tmpPath

Write-Host "Конвертируем dos -> win" -ForegroundColor Green
$fileName = Split-Path $inFile -leaf
./lib/dostowin.exe "$tmpPath\$fileName" > $null

$fileContent = Get-Content "$tmpPath\$fileName"
#$fileContent = Get-Content "$tmpPath\$fileName" | select -First 30

[string]$regPattern = '¦[0-9, " "]{12}¦[0-9, " "]{45}¦[0-9, " ", "."]{17}¦[0-9, " "]{15}¦[0-9, " "]{16}¦'

[int]$maxLine = $fileContent.count
[int]$j = 0
[string]$line = ''
$csvResult = @()

foreach ($curLine in $fileContent)
{		
    if ($curLine -match $regPattern)
    {
        [array]$list = @()
		$list = $curLine.Split("¦")        
        #Пустая строка?         
        if ($list[1].Trim() -ne '')
        {            
            $obj = New-Object PsObject
            $number = $list[1].Trim()
            $obj | Add-Member -MemberType NoteProperty -Name "Номер документа" -Value $number
            
            $account =  $list[2].Trim() -replace '\s+', ' '
            $account = $account.Split(" ")
            $account[0] += '`'
            $account[1] += '`'
            $obj | Add-Member -MemberType NoteProperty -Name "Номер счета по дебету" -Value $account[0]
            $obj | Add-Member -MemberType NoteProperty -Name "Номер счета по кредиту" -Value $account[1]
            
            [double]$sum = $list[3].Trim()

            $obj | Add-Member -MemberType NoteProperty -Name "Сумма в руб и коп" -Value $sum
            $obj | Add-Member -MemberType NoteProperty -Name "СПОД" -Value $list[5].Trim()                     

            $csvResult += $obj
        }
    }
    Write-Progress -Activity $j -PercentComplete ($j / $maxLine * 100) -Status "Фильтрация"
	$j++
}

Write-Host "Экспорт в Excel" -ForegroundColor Green

$csvResult | Export-Excel -Path $outFile -AutoSize -WorkSheetname "sheet1" -TableName BJ

$excel = Open-ExcelPackage $outFile 

$sheet1 = $excel.Workbook.Worksheets["sheet1"]

Set-Format -Address $sheet1.Cells["A:A"] -NumberFormat 'Text' -WrapText -HorizontalAlignment Center
Set-Format -Address $sheet1.Cells["B:B"] -NumberFormat 'Text' -WrapText -HorizontalAlignment Center
Set-Format -Address $sheet1.Cells["C:C"] -NumberFormat 'Text' -WrapText -HorizontalAlignment Center
Set-Format -Address $sheet1.Cells["D:D"] -NumberFormat "0.00" -WrapText -HorizontalAlignment Right
Set-Format -Address $sheet1.Cells["D1"] -NumberFormat 'Text' -WrapText -HorizontalAlignment Center
Set-Format -Address $sheet1.Cells["E:E"] -NumberFormat 'Text' -WrapText -HorizontalAlignment Center

Close-ExcelPackage $excel