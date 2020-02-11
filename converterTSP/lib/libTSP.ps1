function getFileXLS {
    Param($folder)

    $xlsFiles = Get-ChildItem "$folder\*.xls"
    [int]$cnt = ($xlsFiles | Measure-Object).Count

    if ($cnt -eq 0) {
        Write-Error "Xls-файлы в каталоге $folder не найдены!"
        Exit
    }
    if ($cnt -eq 1) {
        return $xlsFiles
    }

    return  $xlsFiles | Sort-Object "File Date" -Descending | Select-Object -First 1
}

Function xlsToCsv {
    Param ($xlsUrl, $tmp)

    Remove-Item "$tmp\*.csv" -force

    try {
        $xl = New-Object -com "Excel.Application"
        $xlCSV = 6

        $wb = $xl.workbooks.open($xlsUrl)
        $csv = "$tmp\$($xlsUrl.BaseName).csv"

        $wb.SaveAs($csv, $xlCSV)
        $xl.displayalerts = $False
        $wb.Close()
    }
    Finally {
        $xl.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($xl) >> $null
    }
    return $csv
}

function convertCsvUtf8 {
    Param ($csvFile, $tmp)

    Get-Content $csvFile | Out-File -FilePath "$csvFile.001" -Encoding UTF8

    Remove-Item "$tmp\*.csv" -force
    Get-ChildItem "$tmp\*.001" | Rename-Item -NewName { $_.name -replace '\.001', '' }
}